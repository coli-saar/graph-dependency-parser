local num_epochs = 10;
local device = 1;
local pos_dim = 50;
local word_dim = 100;
local encoder_output_dim = 512;
local train_data = "data/en_ewt-ud-train.conllu";
local dev_data = "data/en_ewt-ud-dev.conllu";

{
    "dataset_reader": {
        "type": "universal_dependencies",
         "token_indexers": {
            "tokens": {
              "type": "single_id",
              "lowercase_tokens": true
            },
        }
    },
    "iterator": {
        "type": "bucket",
        "batch_size": 64,
        "sorting_keys": [
            [
                "words",
                "num_tokens"
            ]
        ]
    },
    "model": {
        "type": "graph_dependency_parser",
        "edge_model" : {
            "type" : "kg_edges",
            "encoder_dim" : 2*encoder_output_dim, #bidirectional LSTM
            "label_dim": 256,
            "edge_dim": 256,
            #"activation" : "tanh",
            "dropout": 0.1,
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
            "num_layers" : 2,
            "hidden_size": encoder_output_dim,
            "input_size": word_dim + pos_dim
        },
        "pos_tag_embedding":  {
           "embedding_dim": pos_dim,
           "vocab_namespace": "pos"
        },
        "text_field_embedder": {
            "tokens": {
                    "type": "embedding",
                    "embedding_dim": word_dim
                },
        }
    },
    "train_data_path": train_data,
    "validation_data_path": dev_data,
    "trainer": {
        "num_epochs": num_epochs,
         "cuda_device": device,
        "optimizer": {
            "type": "adam",
            "amsgrad" : true
        },
        "validation_metric" : "+LAS",
        "num_serialized_models_to_keep" : 1
    }
}
