function model_cons_residual(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Calculate residual');
    t0 = clock;
end
%%
global data model;
k = varargin{1};
flag_normalization = varargin{2};
loc_rough = 5;
loc_flag_pump = 16;
loc_eta_pump = 17;
% P1 = model.SOC.P1;
% P2 = model.SOC.P2;
c_w = data.BasicParam.Massflow.HeatCapacity;     % kJ/(kg*��)
gravity = data.BasicParam.gravity;                     % m/s^2
data_pipe = data.heatingnetwork.pipe;

num_initialtime = data.initialParam.heatingnetwork.num_initialtime;
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;  % h
num_start = num_initialtime+1;
num_end = num_initialtime+num_heatperiod;
num_pipe = size(data.heatingnetwork.pipe,1);
num_aux = size(model.record.bounds(end).heatingnetwork.aux_alpha_max,1);
heat_coefficient = 1/3600*c_w;
eta_pump = data_pipe(data_pipe(:,loc_flag_pump)==1, loc_eta_pump);
%%
if isempty(model.record.solution)
    num_period = 0;
    num_es = 0;
else
    [num_period, num_es] = size(model.record.solution(end).solution.grid.es.p_chr_state);
end
define_variables();
%%
model.cons_CCP = [];
%%
length_solution = length(model.record.solution);
if length_solution == 0
    model.var.penalty(length_solution+1) = 0;
    k = 0;
elseif length_solution >= 1
    Cons_variables();
    % % x0'*P*x0 + 2x0'*P*(x-x0) = -x0'*P*x0 + 2x0'*P*x
    % % aux_alpha_product_residual
    Cons_aux_alpha_residual();
    % % aux_beta_product_residual
    Cons_aux_beta_residual();
    % % aux_M_alpha_redisual
    Cons_aux_M_alpha_residual();
    % % aux_M_beta_redisual
    Cons_aux_M_beta_residual();
    % % aux_h_pipe_s_in
    Cons_aux_h_pipe_s_in();
    % % aux_h_pipe_r_in
    Cons_aux_h_pipe_r_in();
    % % h_pipe_s
    Cons_h_pipe_s();
    % % h_pipe_r
    Cons_h_pipe_r();
    
    Cons_Pressure_loss();
    Cons_Power_pump();
    
end


%%
ratio_temp_1 = 1e0;   % 1e-1 is the best for non-normalization
ratio_temp_2 = 1e0;
model.var.penalty = k * ...
    ( ...
    sum(model.var.heatingnetwork.aux_alpha_product_1_residual(:)) + ...
    sum(model.var.heatingnetwork.aux_alpha_product_2_residual(:)) + ...
    sum(model.var.heatingnetwork.aux_beta_product_1_residual(:)) + ...
    sum(model.var.heatingnetwork.aux_beta_product_2_residual(:)) + ...
    sum(model.var.heatingnetwork.aux_M_alpha_1_residual(:))*ratio_temp_1 + ...
    sum(model.var.heatingnetwork.aux_M_alpha_2_residual(:))*ratio_temp_1 + ...
    sum(model.var.heatingnetwork.aux_M_beta_1_residual(:))*ratio_temp_1 + ...
    sum(model.var.heatingnetwork.aux_M_beta_2_residual(:))*ratio_temp_1 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_s_in_alpha_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_s_in_alpha_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_s_in_beta_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_s_in_beta_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_r_in_alpha_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_r_in_alpha_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_r_in_beta_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.aux_h_pipe_r_in_beta_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_s_in_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_s_in_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_s_out_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_s_out_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_r_in_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_r_in_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_r_out_1_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.h_pipe_r_out_2_residual(:))*ratio_temp_2 + ...
    sum(model.var.heatingnetwork.Pressure_loss_residual(:))*ratio_temp_1^2 + ...
    sum(model.var.heatingnetwork.Power_pump_1_residual(:))*ratio_temp_1^3 + ...
    sum(model.var.heatingnetwork.Power_pump_2_residual(:))*ratio_temp_1^3 ...
    );

%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end

%% *****************************************************************
%%                   Sub Functions
%% *****************************************************************
%% -----------------------------------------------------------------
    function define_variables()
        %         model.var.grid.es.p_chr_state_residual = sdpvar(num_period, num_es);
        
        % % alpha & beta
        model.var.heatingnetwork.aux_alpha_product_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_alpha_product_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_beta_product_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_beta_product_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        
        % % aux_M
        model.var.heatingnetwork.aux_M_alpha_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_M_alpha_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_M_beta_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_M_beta_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        
        % % aux_h
        model.var.heatingnetwork.aux_h_pipe_s_in_alpha_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_in_alpha_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_in_beta_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_in_beta_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_alpha_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_alpha_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_beta_1_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_beta_2_residual = sdpvar(num_aux,num_pipe,num_heatperiod);
        
        % % h
        model.var.heatingnetwork.h_pipe_s_in_1_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_s_in_2_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_s_out_1_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_s_out_2_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_in_1_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_in_2_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_out_1_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_out_2_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        
        % % pressure and pump
        model.var.heatingnetwork.Pressure_loss_residual = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.Power_pump_1_residual = sdpvar(num_initialtime+num_heatperiod, 1);
        model.var.heatingnetwork.Power_pump_2_residual = sdpvar(num_initialtime+num_heatperiod, 1);
    end
%% -----------------------------------------------------------------
%% x >= 0
    function Cons_variables()
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_alpha_product_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_alpha_product_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_beta_product_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_beta_product_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_M_alpha_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_M_alpha_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_M_beta_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_M_beta_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_s_in_alpha_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_s_in_alpha_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_s_in_beta_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_s_in_beta_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_r_in_alpha_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_r_in_alpha_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_r_in_beta_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.aux_h_pipe_r_in_beta_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_s_in_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_s_in_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_s_out_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_s_out_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_r_in_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_r_in_2_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_r_out_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.h_pipe_r_out_2_residual >= 0) : '');
        
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.Pressure_loss_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.Power_pump_1_residual >= 0) : '');
        model.cons_CCP = model.cons_CCP + (( ...
            model.var.heatingnetwork.Power_pump_2_residual >= 0): '');
    end

%% -----------------------------------------------------------------
    function Cons_aux_alpha_residual()
        i = 1:num_aux - 1;
        j = 1:num_pipe;
        t = 1:num_heatperiod;
        % % aux_alpha_product_1
        temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) + ...
            model.record.solution(end).solution.heatingnetwork.aux_alpha(i+1,j,t);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.var.heatingnetwork.aux_alpha_product_1(i,j,t) - ...
            (2 * temp_k(i,j,t) .* ...
            (model.var.heatingnetwork.aux_alpha(i,j,t) + model.var.heatingnetwork.aux_alpha(i+1,j,t)) - ...
            temp_k(i,j,t).^2) <= ...
            model.var.heatingnetwork.aux_alpha_product_1_residual(i,j,t)) : '');
        
        % % aux_alpha_product_2
        temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) - ...
            model.record.solution(end).solution.heatingnetwork.aux_alpha(i+1,j,t);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.var.heatingnetwork.aux_alpha_product_2(i,j,t) - ...
            (2 * temp_k(i,j,t) .* ...
            (model.var.heatingnetwork.aux_alpha(i,j,t) - model.var.heatingnetwork.aux_alpha(i+1,j,t)) - ...
            temp_k(i,j,t).^2) <= ...
            model.var.heatingnetwork.aux_alpha_product_2_residual(i,j,t)) : '');
    end

%% -----------------------------------------------------------------
    function Cons_aux_beta_residual()
        i = 1:num_aux - 1;
        j = 1:num_pipe;
        t = 1:num_heatperiod;
        % % aux_beta_product_1
        temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) + ...
            model.record.solution(end).solution.heatingnetwork.aux_beta(i+1,j,t);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.var.heatingnetwork.aux_beta_product_1(i,j,t) - ...
            (2 * temp_k(i,j,t) .* ...
            (model.var.heatingnetwork.aux_beta(i,j,t) + model.var.heatingnetwork.aux_beta(i+1,j,t)) - ...
            temp_k(i,j,t).^2) <= ...
            model.var.heatingnetwork.aux_beta_product_1_residual(i,j,t)) : '');
        
        % % aux_beta_product_2
        temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) - ...
            model.record.solution(end).solution.heatingnetwork.aux_beta(i+1,j,t);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.var.heatingnetwork.aux_beta_product_2(i,j,t) - ...
            (2 * temp_k(i,j,t) .* ...
            (model.var.heatingnetwork.aux_beta(i,j,t) - model.var.heatingnetwork.aux_beta(i+1,j,t)) - ...
            temp_k(i,j,t).^2) <= ...
            model.var.heatingnetwork.aux_beta_product_2_residual(i,j,t)) : '');
    end

%% -----------------------------------------------------------------
    function Cons_aux_M_alpha_residual()
        i = 1:num_aux;
        j = 1:num_pipe;
        % %
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_M_alpha_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_M_alpha_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_M_alpha_1_residual
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_massflow * ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_massflow*model.var.heatingnetwork.aux_M_alpha_1(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_massflow*model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) -...
                temp_k(i,j,t).^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_M_alpha_1_residual(i,j,t)) : '');
        end
        % % aux_M_beta_2_residual
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_massflow * ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_massflow*model.var.heatingnetwork.aux_M_alpha_2(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_massflow*model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) -...
                temp_k(i,j,t).^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_M_alpha_2_residual(i,j,t)) : '');
        end
    end

%% -----------------------------------------------------------------
    function Cons_aux_M_beta_residual()
        i = 1:num_aux;
        j = 1:num_pipe;
        % %
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_M_beta_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_M_beta_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_M_beta_1_residual
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_massflow * ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_massflow*model.var.heatingnetwork.aux_M_beta_1(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_massflow*model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) -...
                temp_k(i,j,t).^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_M_beta_1_residual(i,j,t)) : '');
        end
        % % aux_M_beta_2_residual
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_massflow * ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_massflow*model.var.heatingnetwork.aux_M_beta_2(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_massflow*model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) -...
                temp_k(i,j,t).^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_M_beta_2_residual(i,j,t)) : '');
        end
    end

%% -----------------------------------------------------------------
    function Cons_aux_h_pipe_s_in()
        i = 1:num_aux;
        j = 1:num_pipe;
        % % aux_h_pipe_s_in_alpha
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_alpha_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_alpha_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_h_pipe_s_in_alpha_1
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j);            
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_s_in_alpha_1(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j)) - ...
                temp_k(i,j,t).^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_h_pipe_s_in_alpha_1_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_s_in_alpha_2
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j);            
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_s_in_alpha_2(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j)) - ...
                temp_k(i,j,t).^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_h_pipe_s_in_alpha_2_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_s_in_beta
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_beta_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_beta_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_h_pipe_s_in_beta_1
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j);            
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_s_in_beta_1(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j)) - ...
                temp_k(i,j,t).^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_h_pipe_s_in_beta_1_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_s_in_beta_2
        for t = 1:num_heatperiod
            temp_k(i,j,t) = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j);            
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_s_in_beta_2(i,j,t) - ...
                (2 * temp_k(i,j,t) .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,j)) - ...
                temp_k(i,j,t).^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_h_pipe_s_in_beta_2_residual(i,j,t)) : '');
        end
    end

%% -----------------------------------------------------------------
    function Cons_aux_h_pipe_r_in()
        i = 1:num_aux;
        j = 1:num_pipe;
        % % aux_h_pipe_r_in_alpha
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_alpha_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_alpha_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_h_pipe_r_in_alpha_1
        for t = 1:num_heatperiod
            temp_k = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_r_in_alpha_1(i,j,t) - ...
                (2 * temp_k .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) + ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j)) - ...
                temp_k.^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_h_pipe_r_in_alpha_1_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_r_in_alpha_2
        for t = 1:num_heatperiod
            temp_k = model.record.solution(end).solution.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_r_in_alpha_2(i,j,t) - ...
                (2 * temp_k .* ...
                (model.var.heatingnetwork.aux_alpha(i,j,t) - ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j)) - ...
                temp_k.^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_h_pipe_r_in_alpha_2_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_r_in_beta
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_beta_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_beta_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_aux,num_pipe,num_heatperiod);
            temp_base_2 = ones(num_aux,num_pipe,num_heatperiod);
        end
        % % aux_h_pipe_r_in_beta_1
        for t = 1:num_heatperiod
            temp_k = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_r_in_beta_1(i,j,t) - ...
                (2 * temp_k .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) + ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j)) - ...
                temp_k.^2) <= ...
                temp_base_1(i,j,t).*model.var.heatingnetwork.aux_h_pipe_r_in_beta_1_residual(i,j,t)) : '');
        end
        
        % % aux_h_pipe_r_in_beta_2
        for t = 1:num_heatperiod
            temp_k = model.record.solution(end).solution.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_h * ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j);
            model.cons_CCP = model.cons_CCP + (( ...
                4*model.SOC.ratio_aux_h*model.var.heatingnetwork.aux_h_pipe_r_in_beta_2(i,j,t) - ...
                (2 * temp_k .* ...
                (model.var.heatingnetwork.aux_beta(i,j,t) - ...
                model.SOC.ratio_aux_h*model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,j)) - ...
                temp_k.^2) <= ...
                temp_base_2(i,j,t).*model.var.heatingnetwork.aux_h_pipe_r_in_beta_2_residual(i,j,t)) : '');
        end
    end

%% -----------------------------------------------------------------
    function Cons_h_pipe_s()
        t = num_start:num_end;
        j = 1:num_pipe;
        % % h_pipe_s_in
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.h_pipe_s_in_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.h_pipe_s_in_2;
            temp_base_2(temp_base_2<1) = 1;            
        else
            temp_base_1 = ones(num_initialtime+num_heatperiod,num_pipe);
            temp_base_2 = ones(num_initialtime+num_heatperiod,num_pipe);            
        end
        % % h_pipe_s_in_1
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,j) + ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_s_in_1(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_s_in(t,j) + ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_1(t,j).*model.var.heatingnetwork.h_pipe_s_in_1_residual(t,j)) : '');
        
        % % h_pipe_s_in_2
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,j) - ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_s_in_2(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_s_in(t,j) - ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_2(t,j).*model.var.heatingnetwork.h_pipe_s_in_2_residual(t,j)) : '');
        
        % % h_pipe_s_out
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.h_pipe_s_out_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.h_pipe_s_out_2;
            temp_base_2(temp_base_2<1) = 1;            
        else
            temp_base_1 = ones(num_initialtime+num_heatperiod,num_pipe);
            temp_base_2 = ones(num_initialtime+num_heatperiod,num_pipe);            
        end
        % % h_pipe_s_out_1
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,j) + ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_s_out_1(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_s_out(t,j) + ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_1(t,j).*model.var.heatingnetwork.h_pipe_s_out_1_residual(t,j)) : '');
        
        % % h_pipe_s_out_2
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,j) - ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_s_out_2(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_s_out(t,j) - ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_2(t,j).*model.var.heatingnetwork.h_pipe_s_out_2_residual(t,j)) : '');
    end

%% -----------------------------------------------------------------
    function Cons_h_pipe_r()
        t = num_start:num_end;
        j = 1:num_pipe;
        % % h_pipe_r_in
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.h_pipe_r_in_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.h_pipe_r_in_2;
            temp_base_2(temp_base_2<1) = 1;            
        else
            temp_base_1 = ones(num_initialtime+num_heatperiod,num_pipe);
            temp_base_2 = ones(num_initialtime+num_heatperiod,num_pipe);            
        end
        % % h_pipe_r_in_1
        temp_k(t,j)= model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,j) + ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_r_in_1(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_r_in(t,j) + ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_1(t,j).*model.var.heatingnetwork.h_pipe_r_in_1_residual(t,j)) : '');
        
        % % h_pipe_r_in_2
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,j) - ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_r_in_2(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_r_in(t,j) - ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_2(t,j).*model.var.heatingnetwork.h_pipe_r_in_2_residual(t,j)) : '');
        
        % % h_pipe_r_out
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.h_pipe_r_out_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.h_pipe_r_out_2;
            temp_base_2(temp_base_2<1) = 1;            
        else
            temp_base_1 = ones(num_initialtime+num_heatperiod,num_pipe);
            temp_base_2 = ones(num_initialtime+num_heatperiod,num_pipe);            
        end
        % % h_pipe_r_out_1
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,j) + ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_r_out_1(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_r_out(t,j) + ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_1(t,j).*model.var.heatingnetwork.h_pipe_r_out_1_residual(t,j)) : '');
        
        % % h_pipe_r_out_2
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,j) - ...
            model.SOC.ratio_h*model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons_CCP = model.cons_CCP + (( ...
            4*model.SOC.ratio_h*model.var.heatingnetwork.h_pipe_r_out_2(t,j) - ...
            heat_coefficient * (2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Tau_pipe_r_out(t,j) - ...
            model.SOC.ratio_h*model.var.heatingnetwork.Massflow(t,j)) - ...
            temp_k(t,j).^2) <= ...
            temp_base_2(t,j).*model.var.heatingnetwork.h_pipe_r_out_2_residual(t,j)) : '');
    end

%% -----------------------------------------------------------------
    function Cons_Pressure_loss()
        t = num_start:num_end;
        j = 1:num_pipe;
        if flag_normalization
            temp_base = model.record.solution(end).solution.heatingnetwork.Pressure_loss;
            temp_base(temp_base<1) = 1;
        else
            temp_base = ones(num_initialtime+num_heatperiod,num_pipe);
        end
        model.cons_CCP = model.cons_CCP + (( ...
            (model.var.heatingnetwork.Pressure_loss(t,j) - ...
            1/3.6^2 * ones(num_heatperiod,1)*data_pipe(j,loc_rough)'.* ( ...
            2*model.record.solution(end).solution.heatingnetwork.Massflow(t,j).* ...
            model.var.heatingnetwork.Massflow(t,j) - ...
            model.record.solution(end).solution.heatingnetwork.Massflow(t,j).^2 ...
            )) <= ...
            temp_base(t,j).*model.var.heatingnetwork.Pressure_loss_residual(t,j)) : '');
    end

%% -----------------------------------------------------------------
    function Cons_Power_pump()
        t = num_start:num_end;
        j = 1:1;
        if flag_normalization
            temp_base_1 = model.record.solution(end).solution.heatingnetwork.Power_pump_1;
            temp_base_1(temp_base_1<1) = 1;
            temp_base_2 = model.record.solution(end).solution.heatingnetwork.Power_pump_2;
            temp_base_2(temp_base_2<1) = 1;
        else
            temp_base_1 = ones(num_initialtime+num_heatperiod,num_pipe);
            temp_base_2 = ones(num_initialtime+num_heatperiod,num_pipe);
        end
        % % Power_pump_1
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Pressure_pump(t,j) + ...
            model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons = model.cons + (( ...
            4*model.var.heatingnetwork.Power_pump_1(t,j) - ...
            1/3600*gravity/eta_pump * ( ...
            2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Pressure_pump(t,j) + ...
            model.var.heatingnetwork.Massflow(t,j)) - temp_k(t,j).^2) <= ...
            temp_base_1(t,j).*model.var.heatingnetwork.Power_pump_1_residual(t,j)) : '');
        
         % % Power_pump_2
        temp_k(t,j) = model.record.solution(end).solution.heatingnetwork.Pressure_pump(t,j) - ...
            model.record.solution(end).solution.heatingnetwork.Massflow(t,j);
        model.cons = model.cons + (( ...
            4*model.var.heatingnetwork.Power_pump_2(t,j) - ...
            1/3600*gravity/eta_pump * ( ...
            2 * temp_k(t,j) .* ...
            (model.var.heatingnetwork.Pressure_pump(t,j) - ...
            model.var.heatingnetwork.Massflow(t,j)) - temp_k(t,j).^2) <= ...
            temp_base_2(t,j).*model.var.heatingnetwork.Power_pump_2_residual(t,j)) : '');
    end
end