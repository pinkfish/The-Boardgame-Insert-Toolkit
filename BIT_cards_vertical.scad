
include <boardgame_insert_toolkit_lib.1.18.scad>;

// determines whether lids are output.
g_b_print_lid = 1;

// determines whether boxes are output.
g_b_print_box = 1; 

// Focus on one box
g_isolated_print_box = ""; 

// Used to visualize how all of the boxes fit together. 
// Turn off for printing.
g_b_visualization = 0;          

// Makes solid simple lids instead of the honeycomb ones.
// Might be faster to print. Definitely faster to render.
g_b_simple_lids = 1;            


// creates the indentation on the bottom of the box 
//that allows the lid to be put under when in play.
g_b_fit_lid_underneath = 0; 

// this is the outer wall thickness. 
//Default = 1.5
g_wall_thickness = 1.5;

// this is the thickness of partitions between compartments
// Default = 1
g_partition_thickness = 1.0;

// this is the width of partitions that are for 
// inserting fingers to grab the bits.
// default = 13
g_finger_partition_thickness = 13;
 

// 285 x 285 x 50
data =
[
    [   "cards",
        [
            [ "box_dimensions", [69, 18, 92] ],                       // float f -- default:[ 100, 100, 100 ]
            [ "label",
                [
            //        [ "text",   "Tussie Mussie"],
                    [ "size",   6 ],
                    ["rotation",                        0 ],
                ]
            ],
            
            [   "components",
                [
                    [   "cards",
                        [
                            ["enabled",                         1 ],                        // true | false
                            ["type",                            "cards"],                   // "cards" | "tokens" | "chit_stack" | "chit_stack_vertical" | "" -- default: ""
                            ["shape",                           ""],                 // "round" | "hex" | "hex_rotated" | "square" -- default: "square"
                            ["compartment_size",                [ 66, 15, 91] ],      // [float, float, float]
                    // [float,float]
                            ["position",                        ["center", "center" ] ],                // [float, float, float]
                            ["rotation",                        0 ],
                        ]
                    ],
                ]
            ]
        ]
    ],

 
    
];


MakeAll();