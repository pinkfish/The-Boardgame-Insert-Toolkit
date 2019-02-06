
// Copyright 2019 MysteryDough https://www.thingiverse.com/MysteryDough/
//
// Released under the Creative Commons - Attribution - Non-Commercial - Share Alike License.
// https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode

VERSION = "1.03";
COPYRIGHT_INFO = "\tThe Boardgame Insert Toolkit\n\thttps://www.thingiverse.com/thing:3405465\n\n\tCopyright 2019 MysteryDough\n\tCreative Commons - Attribution - Non-Commercial - Share Alike.\n\thttps://creativecommons.org/licenses/by-nc-sa/4.0/legalcode";

$fn=100;

// constants
KEY = 0;
VALUE = 1;

X = 0;
Y = 1;
Z = 2;

DISTANCE_BETWEEN_PARTS = 10;
////////////////////

// key-values helpers
function __get_index_of_key( table, key ) = search( [ key ], table )[ KEY ];
function __get_value( table, key, default = false ) = __get_index_of_key( table, key ) == [] ? default : table[ __get_index_of_key( table, key ) ][ VALUE ];

///////////////////////

module RotateAboutPoint(a, v, pt) 
{
    translate(pt)
    {
        rotate(a,v)
        {
            translate(-pt)
            {
                children();   
            }
        }
    }
}

module MirrorAboutPoint( v, pt) 
{
    translate(pt)
    {
        mirror( v )
        {
            translate(-pt)
            {
                children();   
            }
        }
    }
}


module MakeAll()
{
    function __get_box( b ) = data[ b ][1];
    function __num_boxes() = len( data );

    function __box_isolated_for_print() = __get_index_of_key( data, b_print_box ) != [];
    function __box_enabled( b ) = __get_value( __get_box( b ), "enabled", default = true);
    function __box_dimensions( b, D ) = __get_value( __get_box( b ), "box_dimensions" )[ D ];
    function __box_position( b ) = __get_box( b - 1 ) == undef ? 0 : __box_enabled( b - 1 ) ? __box_dimensions( b - 1, X ) + __box_position( b - 1 ) + DISTANCE_BETWEEN_PARTS : __box_dimensions( b - 2, X ) + __box_position( b - 2 ) + DISTANCE_BETWEEN_PARTS;

    echo( str( "\n\n\n", COPYRIGHT_INFO, "\n\n\tVersion ", VERSION, "\n\n" ));

    if ( __box_isolated_for_print() )
    {
        MakeBox( __get_value( data, b_print_box ) );
    }
    else
    {
        for( b = [ 0: __num_boxes() - 1 ] )
        {
            
            translate( [ __box_position( b ), 0, 0 ] )
            {
                if ( __box_enabled( b ) )
                {
                    MakeBox( __get_box( b ) );
                }
            }
        }
    }

}


module MakeBox( box )
{
    function __box_dimensions( D ) = __get_value( box, "box_dimensions", default = [ 100.0, 100.0, 100.0 ] )[ D ];


    function __get_components() =  __get_value( box, "components" );
    function __num_components() =  len( __get_components() );
    function __get_component( c ) = __get_components()[ c ][1];

    if( b_print_lid )    
    {
        MakeLayer( layer = "lid");
    }
    
    if ( b_print_box )
    {
render(convexity = 1)
        difference()
        {
            union()
            {
                // carve out components from box
                difference()
                {
                    MakeLayer( layer = "outerbox" );

                    for( i = [ 0: __num_components() - 1 ] )
                    {
                        MakeLayer( __get_component( i ) , layer = "carve_outs");
                    }
                }


                // now add the positive elements
                for( i = [ 0: __num_components() - 1 ] )
                {
                    MakeLayer( __get_component( i ), layer = "additive_components" );     
                }
            }

            // last additive_components to carve out from everything
            for( i = [ 0: __num_components() - 1 ] )
            {
                MakeLayer( __get_component( i ), layer = "final_carve_outs" );
            }
        }
    }
    


    module MakeLayer( component, layer = "" )
    {
        function __is_outerbox() = layer == "outerbox";
        function __is_lid() = layer == "lid";

        // we don't use position for the box or the lid. Only for components.
        function __ignore_position() = __is_outerbox() || __is_lid();

        function __is_carve_outs() = layer == "carve_outs";
        function __is_additive_components() = layer == "additive_components";
        function __is_final_carve_outs() = layer == "final_carve_outs";

        function __compartment_size( D ) = __get_value( component, "compartment_size", default = [10.0, 10.0, 10.0] )[ D ];
        function __compartments_num( D ) = __get_value( component, "num_compartments", default = [1,1] )[ D ];

        function __component_rotation_raw() = __get_value( component, "rotation", default = 0 );
        function __component_rotation_clean() = __component_rotation_raw() == 1 ? 1 : __component_rotation_raw() == 0 ? 0 : 0; // restrict values to 0, 1
        function __component_rotation() = __component_rotation_clean() * 90;
        function __component_shape() = __get_value( component, "shape", default = "square" );
        function __component_type() = __get_value( component, "type", default = "generic" );
        function __component_extra_spacing( D ) = __get_value( component, "extra_spacing", default = [0.0, 0.0] )[ D ];
        function __component_enabled() = __get_value( component, "enabled", default = true);

        /////////

        function __is_cards() = __component_type() == "cards";
        function __is_tokens() = __component_type() == "tokens";
        function __is_chit_stack() = __component_type() == "chit_stack";
        function __is_chit_stack_vertical() = __component_type() == "chit_stack_vertical";

        function __req_thick_partitions() = __is_cards() || __is_chit_stack() || __is_chit_stack_vertical();
        function __req_lower_partitions() = __is_chit_stack();
        function __req_bottoms() = __is_tokens() || ( __is_chit_stack() && __component_shape() != "square" );
        function __req_single_end_partition() = __is_cards() || __is_chit_stack_vertical();
        function __req_double_end_partition() = __is_chit_stack();

        ///////////

        // tolerance for fittings
        function __tolerance() = 0.1; 

        // __wall_local determins the lid-less (part) __wall width.
        // Wall exterior is added on and creates the sturdier exterior that also holds the lid.
        function __wall_thickness() = 2.0;

        // this is the difference between the two __walls that
        // forms the lip that the lid fits on.
        function __wall_lip_height() = 8.0;

    
        function __partition_height_scale( D ) = D == Y ? __req_lower_partitions() ? min( 0.5, (__compartment_size( X ) / __compartment_size( Z )) /2) : 1.00 : 1.00;

        // Amount of curvature represented as a percentage of the __wall height.
        function __bottom_curve_height_scale() = 0.50;

        function __b_corner_notch() = 1;

        // DERIVED VARIABLES

        ///////// __component_position helpers

        function __p_i_c( D) = __c_p_raw()[ D ] == "center";
        function __p_i_m( D) = __c_p_raw()[ D ] == "max";
        function __c_p_c( D ) = ( __box_dimensions( D ) - __component_size( D )) / 2;
        function __c_p_max( D ) = __box_dimensions( D ) - __wall_thickness() -  __component_size( D );

        /////////

        function __c_p_raw() = __get_value( component, "position", default = [ "center", "center" ]);
        function __component_position( D ) = __p_i_c( D )? __c_p_c( D ): __p_i_m( D )? __c_p_max( D ): __c_p_raw()[D] < 0 ? __c_p_max( D ) + __c_p_raw()[D] : __c_p_raw()[D] + __wall_thickness();

        // The thickness of the __compartment __partitions.
        function __partition_thickness( D ) = ( D == Y ) && __req_thick_partitions() ? 10 + __component_extra_spacing( D ): 1 + __component_extra_spacing( D );

        // whether to add __partitions on the __box edges.
        function __partition_num_modifier( D ) = ( D == Y ) ? ( __req_single_end_partition() ? 0 : __req_double_end_partition() ? 1 : -1 ) : -1 ;

        // Determines whether finger cutouts are made. (For cards)
        function __finger_cutouts() = __is_cards() || __is_chit_stack_vertical();

        // for rounded bottoms, use the lowest __wall
        function __get_height_for_rounded_bottom() = 
            ( min( __partition_height( Y ), min( __bottom_curve_height_scale() * __compartment_size( Z ), __partition_height( X ) )));

        function __compartment_smallest_size() = ( __compartment_size( X ) < __compartment_size( Y ) ) ? __compartment_size( X ) : __compartment_size( Y );

        function __partitions_num( D )= __compartments_num( D ) + __partition_num_modifier( D );

        // calculated __box local dimensions
        function __component_size( D )= ( D == Z ) ? __compartment_size( Z ) : ( __compartment_size( D )* __compartments_num( D )) + ( __partitions_num( D )* __partition_thickness( D ));

        // clamp __partition heights
        function __partition_height( D ) = __compartment_size( Z ) * __partition_height_scale( D );

        function __notch_length( D ) = __box_dimensions( D ) / 5.0;
        function __notch_depth() = __wall_thickness();

        function __notch_height() = 3.0;

        function __lid_external_size( D )= D == Z ? __wall_thickness() + __wall_lip_height() - __tolerance() : __box_dimensions( D );
        function __lid_internal_size( D )= D == Z ? __lid_external_size( Z ) - __wall_thickness() : __lid_external_size( D ) - ( __wall_thickness() - __tolerance() );
  
        module RotateComponentInPlace()
        {
          //  x_offset = __component_rotation() == 90 ? __component_exterior_size( Y ) : 0;
            y_offset = __component_rotation() == 90 ? __component_size( X ) : 0;

            pivot = [ 0,0, 0];

            translate( [ 0, y_offset, 0] )
                RotateAboutPoint(  - __component_rotation(), [0,0,1], pivot )
                    children();
        }

/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////

        if ( __component_enabled() )
        {
            if ( __ignore_position() )
            {
                InnerLayer();
            }
            else
            { 
                translate( [ __component_position( X ), __component_position( Y ), __box_dimensions( Z ) - __compartment_size( Z ) ] )
                {
                    RotateComponentInPlace()
                    {
                        InnerLayer();
                    }
                }
            }
        }

        module InnerLayer()
        {
            if ( __is_outerbox() )
            {
                // 'outerbox' is the insert. It may contain one or more 'components' that each
                // define a repeated compartment type.
                //

                difference()
                {
                    // outer, shorter wall
                    cube([  __box_dimensions( X ), 
                            __box_dimensions( Y ), 
                            __box_dimensions( Z ) - __wall_lip_height()]);

                            MakeLidNotches();
                }

                // inner, taller wall
                translate( [__wall_thickness()/2, __wall_thickness()/2, 0 ] )
                {
                    cube([  __box_dimensions( X ) - __wall_thickness(), 
                            __box_dimensions( Y ) - __wall_thickness(), 
                            __box_dimensions( Z )]);
                }             
            }
            else if ( __is_lid() )
            {
                MakeLid();
            }
            else if ( __is_carve_outs() ) 
            {
                // 'carve-outs' are the big shapes of the 'components.' Each is then subdivided
                // by adding partitions.
              
                cube([  __component_size( X ), 
                        __component_size( Y ), 
                        __component_size( Z )]);
                
            }
            else if ( __is_additive_components() )
            {
                MakePartitions();
            }
            else if ( __is_final_carve_outs() )
            {
                // Some shapes, such as the finger cutouts for card compartments
                // need to be done at the end becaause they substract from the 
                // entire box.

                // finger cutouts
                if ( __finger_cutouts() )
                {
                    InEachCompartment( y_modify = 0, only_y = false, only_x = true  )
                    {
                        MakeFingerCutout( axis = "x" );
                    }
                }
            }
        }

        module MakeLid() 
        {
            // move the lid to the side
            translate([0, - __box_dimensions( Y ) - DISTANCE_BETWEEN_PARTS, 0 ]) 
            {
                difference() 
                {
                    // main __box
                    cube([__lid_external_size( X ), __lid_external_size( Y ), __lid_external_size( Z )]);
                    
                    translate([ ( __wall_thickness() - __tolerance() )/2 , ( __wall_thickness() - __tolerance() )/2, __wall_thickness()]) 
                    {
                        cube([  __lid_internal_size( X ), __lid_internal_size( Y ), __lid_internal_size( Z )]);
                    }
                }
            }
        }

        module InEachCompartment( x_modify = 0, y_modify = 0 , only_x = false, only_y = false )
        {
            n_x = only_y ? 1  : __compartments_num( X ) + x_modify;
            n_y = only_x ? 1 : __compartments_num( Y ) + y_modify;

            b_continue = only_x ? n_x > 0 : only_y ? n_y > 0 : true;  
            
            if ( b_continue )
            {
                for ( x = [ 0: n_x - 1] )
                {
                    x_pos = ( __compartment_size( X ) + __partition_thickness( X ) ) * x;

                    for ( y = [ 0: n_y - 1] )
                    {
                        y_pos = ( ( __compartment_size( Y ) ) + __partition_thickness( Y ) ) * y;

                        translate( [ x_pos ,  y_pos , 0 ] )
                        {
                            children();
                        }
                    }
                }
            }
        }

        module MakeFingerCutout()
        {
            cutout_length = __is_chit_stack_vertical() ? __component_size( Y ) / 2 : __component_size( Y );

            cutout_width =  __is_chit_stack_vertical() ? __compartment_size( X ) * .6 : __compartment_size( X ) * .5;
            cutout_height = __box_dimensions( Z ) - 2.0;
            base = max( -10, __compartment_size( Z ) - __box_dimensions( Z ) + 2.0 );

            translate( [ __compartment_size( X )/2 - cutout_width/2, 0, base ] )
            {
                cube([ cutout_width , cutout_length, cutout_height ]);
            }
        }


        // this rounds out the bottoms regardless of the size of the compartment
        // and doesn't attempt to fit a specific shape.
       module MakeBottomsRounded()
        {
            r = __get_height_for_rounded_bottom();

            difference()
            { 
                // blocks
                union()
                {
                    cube ( [ r, __compartment_size( Y ), r ] );
                    
                    translate( [ __compartment_size( X ) - r, 0, 0] )
                    {
                        cube ( [ r, __compartment_size( Y ), r ] );
                    }
                }

                // cylinders
                union()
                {
                    translate( [ r, __compartment_size( Y ) , r ] )
                    {
                        rotate( [ 90, 0, 0 ], 0 )
                        {
                            cylinder(h = __compartment_size( Y ), r1 = r, r2 = r);  
                        } 
                    }

                    translate( [ __compartment_size( X ) - r, __compartment_size( Y ) , r ] )
                    {
                        rotate( [ 90, 0, 0 ], 0 )
                        {
                            cylinder(h = __compartment_size( Y ), r1 = r, r2 = r);  
                        } 
                    }
                }
            }
                    
        }

        module MakeBottoms()
        {
            $fn = __component_shape() == "hex" ? 6 : 100;

            r = __compartment_size( X )/2;
 
            start_pos_y =  __partition_thickness( Y );

            translate( [ 0, start_pos_y, 0 ] )
            {
                difference()
                { 
                    // blocks

                    cube ( [ __compartment_size( X ), __compartment_size( Y ), __compartment_size( Z ) / 2 ] );
                    

                    // cylinders
                    union()
                    {
                        translate( [ r , __compartment_size( Y ) , r ] )
                        {
                            rotate( 90, [1, 0, 0] )
                            {
                                cylinder(h = __compartment_size( Y ), r1 = r, r2 = r );  
                            } 
                        }

                        translate( [ 0,0, r ])
                        {
                            cube ( [ __compartment_size( X ), __compartment_size( Y ), __box_dimensions( Z )] );
                        }
                    }
                }       
            }    
        }

        module ShapeCompartment()
        {
            $fn = __component_shape() == "hex" ? 6 : 100;

            r = __compartment_smallest_size()/2;
 
            {
                difference()
                { 
                    // blocks

                    cube ( [ __compartment_size( X ), __compartment_size( Y ) + __partition_thickness(Y), __compartment_size( Z ) ] );
                    
                    // cylinders

                    translate( [ r , r + __partition_thickness(Y) , r ] )
                    {
                        rotate( 30, [0, 0, 1] )
                        {
                            cylinder(h = __compartment_size( Y ), r1 = r, r2 = r, center = true );  
                        } 
                    }
                }       
            }    
        }

        module MakePartitions()
        {
            InEachCompartment( only_x = true, x_modify = __partition_num_modifier( X ) )   
            {
                MakePartition( axis = "x");  
            }

            InEachCompartment( only_y = true, y_modify = __partition_num_modifier( Y ) )  
            {
                MakePartition( axis = "y");  
            }


            InEachCompartment( x_modify = 0, y_modify = 0 )
            {
                if ( __req_bottoms() )
                {
                    if ( __is_chit_stack() )
                        MakeBottoms();
                    else if ( __is_tokens() )
                        MakeBottomsRounded();
                }
                
                if ( __is_chit_stack_vertical() )
                    ShapeCompartment();
            }
        }

        module MakePartition( axis = "x" )
        {
            start_pos_x = __partition_num_modifier( X ) > -1 ? 0 : __compartment_size( X );
            start_pos_y = __partition_num_modifier( Y ) > -1 ? 0 : __compartment_size( Y );

            if ( axis == "x" )
            {
                translate( [ start_pos_x, 0, 0 ] )
                {
                    cube ( [ __partition_thickness( X ), __component_size( Y ), __partition_height( X )  ] );
                }
            }
            else if ( axis == "y" )
            {
                translate( [ 0, start_pos_y, 0 ] )
                {
                    cube ( [ __component_size( X ), __partition_thickness( Y ) , __partition_height( Y ) ] );     
                }  
            }
        }

        module MakeCornerNotch()
        {
            notch_pos_z =  __box_dimensions( Z ) - __wall_lip_height() - __notch_height();

            translate([ 0, 0, notch_pos_z]) 
            {
                cube([ __notch_length( X ), __notch_depth(), __notch_height() ]);
            }
            translate([ 0, 0, notch_pos_z]) 
            {
                cube([__notch_depth(), __notch_length( Y ), __notch_height()]);
            }
        }

        module MakeLidNotches()
        {
            MakeCornerNotch();

            MirrorAboutPoint( [1,0,0], [ __box_dimensions( X ) / 2, __box_dimensions( Y ) / 2, 0] )
            {
                MakeCornerNotch();
            }

            MirrorAboutPoint( [0,1,0], [ __box_dimensions( X ) / 2, __box_dimensions( Y ) / 2, 0] )
            {
                MakeCornerNotch();
            }

            MirrorAboutPoint( [1,0,0], [ __box_dimensions( X ) / 2, __box_dimensions( Y ) / 2, 0] )
            {
                MirrorAboutPoint( [0,1,0], [ __box_dimensions( X ) / 2, __box_dimensions( Y ) / 2, 0] )
                {
                    MakeCornerNotch();    
                }
            }
        }
    }

}













