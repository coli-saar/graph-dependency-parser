local num_epochs = 10;
local device = 1;
local pos_dim = 50;
local elmo_path = "/local/mlinde/elmo/"; #TODO change this
local encoder_output_dim = 512;
local train_data = "data/en_ewt-ud-train.conllu";
local dev_data = "data/en_ewt-ud-dev.conllu";
local extern_tools = "external_eval_tools/";

local dataset_reader = {
        "type": "conllu",
        "token_indexers": {
            "elmo": {
              "type": "elmo_characters"
            }
        }
      };
local data_iterator = {
        "type": "bucket",
        "batch_size": 64,
        "sorting_keys": [
            [
                "words",
                "num_tokens"
            ]
        ]
    };

{
    "dataset_reader": dataset_reader,
    "iterator": data_iterator,
    "model": {
        "type": "graph_dependency_parser",
        "edge_model" : {
            "type" : "kg_edges",
            "encoder_dim" : 2*encoder_output_dim, #bidirectional LSTM
            "label_dim": 256,
            "edge_dim": 256,
            #"activation" : "tanh",
        },
        "loss_function" : {
            "existence_loss" : { "type" : "kg_edge_loss", "normalize_wrt_seq_len": false},
            "label_loss" : {"type" : "dm_label_loss" , "normalize_wrt_seq_len": false},
            "existence_coef" : 0.5 #coefficient that mixes edge existence and edge label loss
        },
        "dropout": 0.1,
        "encoder": {
            "type": "lstm",
            "bidirectional" : true,
            "num_layers" : 1,
            "hidden_size": encoder_output_dim,
            "input_size": 1024 + pos_dim
        },
        "pos_tag_embedding":  {
           "embedding_dim": pos_dim,
           "vocab_namespace": "pos"
        },

        "text_field_embedder": {
            "type": "basic",
            "token_embedders": {
                "elmo" : {
                    "type": "elmo_token_embedder",
                        "options_file": elmo_path+"elmo_2x4096_512_2048cnn_2xhighway_options.json",
                        "weight_file": elmo_path+"elmo_2x4096_512_2048cnn_2xhighway_weights.hdf5",
                        "do_layer_norm": false,
                        "dropout": 0.3
                    },
             }
        },

        #optional: set validation evaluator that is called after each epoch.
        "validation_evaluator": {
            "system_input" : dev_data,
            "gold_file": dev_data,
            "predictor" : {
                    "type" : "conllu_predictor",
                    "dataset_reader" : dataset_reader, #same dataset_reader as above.
                    "data_iterator" : data_iterator, #same bucket iterator also for validation.
                    "evaluation_command" : {
                        "type" : "bash_evaluation_command",
                        "command" : "python "+extern_tools+"conll18_ud_eval.py {gold_file} {system_output}",
                        "result_regexes" : { "Official_LAS" : "LAS F1 Score: (?P<value>.+)" }
                    }
            }
        }
    },
    "train_data_path": train_data,
    "validation_data_path": dev_data,
    "trainer": {
        "num_epochs": num_epochs,
         "cuda_device": device,
        "optimizer": {
            "type": "adam",
        },
        "validation_metric" : "+Official_LAS",
        "num_serialized_models_to_keep" : 1
    }
}

