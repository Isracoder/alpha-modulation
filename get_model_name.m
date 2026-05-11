function model_name = get_model_name(Mt , Gt) % can turn this file into a class with functions all related to formatting

    model_name = "" ;
    if (Mt == 0)
        model_name = model_name + "Static Dummy " ;
    elseif (Mt == 1)
        model_name = model_name + "Learning " ;
    elseif (Mt == 3)
        model_name = model_name + "Gamma " ;
    elseif (Mt == 4)
        model_name = model_name + "Kuramoto-hopf " ;
    else
        error ("Unsupported") ;

    end
    % obs model
    if (Gt == 1)
        model_name =model_name + "" ; % kuramoto model mentioned anyways
    elseif (Gt == 2)
        model_name =model_name + "+ SDT " ;
    elseif (Gt == 3)
        model_name =model_name + "+ DDM " ;
    elseif (Gt == 4)
        model_name =model_name + "" ; %
    elseif (Gt == 5)
        model_name =model_name + "+ Energy-bound " ; %
    else
        error ("Unsupported") ;

    end
end