library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package ab_to_dq_transform_pkg is

------------------------------------------------------------------------
    type ab_to_dq_record is record
        ab_to_dq_multiplier_counter : natural range 0 to 15;
        ab_to_dq_calculation_counter : natural range 0 to 15;

        d     : int18;
        d_sum : int18;
        q      : int18;
        q_sum  : int18;

        sine   : int18;
        cosine : int18;
        alpha  : int18;
        beta   : int18;

        ab_to_dq_calculation_is_ready : boolean;
    end record;

    ------------------------------
    constant init_ab_to_dq_transform : ab_to_dq_record := 
        (15 , 15 ,
        0   , 0  , 0 , 0 ,
        0   , 0  , 0 , 0 ,
        false);

------------------------------------------------------------------------
    procedure request_ab_to_dq_transform (
        signal ab_dq_transform_object : out ab_to_dq_record;
        sine                          : in int18;
        cosine                        : in int18;
        d                             : in int18;
        q                             : in int18);
------------------------------------------------------------------------
    procedure create_ab_to_dq_transform (
        signal hw_multiplier          : inout multiplier_record;
        signal ab_dq_transform_object : inout ab_to_dq_record);
------------------------------------------------------------------------


end package ab_to_dq_transform_pkg;

package body ab_to_dq_transform_pkg is

------------------------------------------------------------------------
    procedure request_ab_to_dq_transform
    (
        signal ab_dq_transform_object : out ab_to_dq_record;
        sine                          : in int18;
        cosine                        : in int18;
        d                             : in int18;
        q                             : in int18
    ) is
    begin
        ab_dq_transform_object.ab_to_dq_multiplier_counter <= 0;
        ab_dq_transform_object.ab_to_dq_calculation_counter <= 0;

        ab_dq_transform_object.sine   <= sine  ;
        ab_dq_transform_object.cosine <= cosine;
        ab_dq_transform_object.d      <= d     ;
        ab_dq_transform_object.q      <= q     ;
    end request_ab_to_dq_transform;

------------------------------------------------------------------------
    procedure create_ab_to_dq_transform
    (
        signal hw_multiplier          : inout multiplier_record;
        signal ab_dq_transform_object : inout ab_to_dq_record
    ) is

        alias ab_to_dq_multiplier_counter  is ab_dq_transform_object.ab_to_dq_multiplier_counter ;
        alias ab_to_dq_calculation_counter is ab_dq_transform_object.ab_to_dq_calculation_counter;

        alias d     is ab_dq_transform_object.d    ;
        alias d_sum is ab_dq_transform_object.d_sum;
        alias q      is ab_dq_transform_object.q     ;
        alias q_sum  is ab_dq_transform_object.q_sum ;

        alias sine   is ab_dq_transform_object.sine   ;
        alias cosine is ab_dq_transform_object.cosine ;
        alias alpha  is ab_dq_transform_object.alpha  ;
        alias beta   is ab_dq_transform_object.beta   ;

        alias ab_to_dq_calculation_is_ready is  ab_dq_transform_object.ab_to_dq_calculation_is_ready;

    begin
    --------------------------------------------------

        ab_to_dq_calculation_is_ready <= false;
    --------------------------------------------------
        CASE ab_to_dq_multiplier_counter is
            WHEN 0 => multiply_and_increment_counter(hw_multiplier , ab_to_dq_multiplier_counter , cosine , alpha );
            WHEN 1 => multiply_and_increment_counter(hw_multiplier , ab_to_dq_multiplier_counter , -sine  , beta  );
            WHEN 2 => multiply_and_increment_counter(hw_multiplier , ab_to_dq_multiplier_counter , sine   , alpha );
            WHEN 3 => multiply_and_increment_counter(hw_multiplier , ab_to_dq_multiplier_counter , cosine , beta  );
            WHEN others => -- wait here for retriggering
        end CASE;

    --------------------------------------------------
        CASE ab_to_dq_calculation_counter is
            WHEN 0 =>
                if multiplier_is_ready(hw_multiplier) then
                    d_sum <= get_multiplier_result(hw_multiplier,15);
                    increment(ab_to_dq_calculation_counter);
                end if;
            WHEN 1 =>
                d <= get_multiplier_result(hw_multiplier,15);
                increment(ab_to_dq_calculation_counter);
            WHEN 2 =>
                q_sum <= q_sum + get_multiplier_result(hw_multiplier,15);
                increment(ab_to_dq_calculation_counter);
            WHEN 3 =>
                ab_to_dq_calculation_is_ready <= true;
                q <= q_sum + get_multiplier_result(hw_multiplier,15);
                increment(ab_to_dq_calculation_counter);
            WHEN others => -- hang and wait for start
        end CASE;
    --------------------------------------------------
    end create_ab_to_dq_transform;

------------------------------------------------------------------------
end package body ab_to_dq_transform_pkg;