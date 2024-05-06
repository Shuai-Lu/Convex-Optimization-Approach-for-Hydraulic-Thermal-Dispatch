function Projection(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Calculate projection');
    t0 = clock;
end
%%
global data model;
c_w = data.BasicParam.Massflow.HeatCapacity;     % kJ/(kg*��)
k = 1/3600*c_w;
data_initial = data.initialParam.heatingnetwork;
loc_initial_Tau_r = 2;
num_initialtime = data.initialParam.heatingnetwork.num_initialtime;
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;  % h
num_start = num_initialtime+1;
num_end = num_initialtime+num_heatperiod;
Num_aux = size(model.record.solution(end).solution.heatingnetwork.aux_alpha,1);
%%
t = num_start:num_end;
length_projection = length(model.record.projection);

% % Massflow Tau_pipe
model.record.projection(length_projection+1).Massflow_Tau_pipe_s_in = ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,:).^2)/2;
model.record.projection(length_projection+1).Massflow_Tau_pipe_s_out = ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_s_out(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,:).^2)/2;
model.record.projection(length_projection+1).Massflow_Tau_pipe_r_in = ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,:).^2)/2;
model.record.projection(length_projection+1).Massflow_Tau_pipe_r_out = ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_r_out(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Massflow(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,:).^2)/2;
%%
model.record.projection(length_projection+1).Massflow = ...
    (model.record.projection(length_projection+1).Massflow_Tau_pipe_s_in + ...
    model.record.projection(length_projection+1).Massflow_Tau_pipe_s_out + ...
    model.record.projection(length_projection+1).Massflow_Tau_pipe_r_in + ...
    model.record.projection(length_projection+1).Massflow_Tau_pipe_r_out)/4;

% % Tau_pipe Massflow
model.record.projection(length_projection+1).Tau_pipe_s_in = ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Massflow(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Massflow(t,:).^2)/2;
model.record.projection(length_projection+1).Tau_pipe_s_out = ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Massflow(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_s_out(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_out(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Massflow(t,:).^2)/2;
model.record.projection(length_projection+1).Tau_pipe_r_in = ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Massflow(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_in(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Massflow(t,:).^2)/2;
model.record.projection(length_projection+1).Tau_pipe_r_out = ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,:)/2 + ...
    (k * model.record.solution(end).solution.heatingnetwork.Massflow(t,:) .* ...
    model.record.solution(end).solution.heatingnetwork.h_pipe_r_out(t,:) + ...
    model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(t,:)) ./ ...
    (1 + k^2 * model.record.solution(end).solution.heatingnetwork.Massflow(t,:).^2)/2;
%% ***********************
model.record.projection(length_projection+1).Tau_pipe_r_out(end,:) = data_initial.temperature(loc_initial_Tau_r);

% % h_pipe Massflow
% model.record.projection(length_projection+1).h_pipe_s_in = ...
%     k*model.record.projection(length_projection+1).Massflow .* ...
%     model.record.projection(length_projection+1).Tau_pipe_s_in;
%
% model.record.projection(length_projection+1).h_pipe_s_out = ...
%     k*model.record.projection(length_projection+1).Massflow .* ...
%     model.record.projection(length_projection+1).Tau_pipe_s_out;
%
% model.record.projection(length_projection+1).h_pipe_r_in = ...
%     k*model.record.projection(length_projection+1).Massflow .* ...
%     model.record.projection(length_projection+1).Tau_pipe_r_in;
%
% model.record.projection(length_projection+1).h_pipe_r_out = ...
%     k*model.record.projection(length_projection+1).Massflow .* ...
%     model.record.projection(length_projection+1).Tau_pipe_r_out;

model.record.projection(length_projection+1).h_pipe_s_in = ...
    k*model.record.projection(length_projection+1).Massflow_Tau_pipe_s_in .* ...
    model.record.projection(length_projection+1).Tau_pipe_s_in;

model.record.projection(length_projection+1).h_pipe_s_out = ...
    k*model.record.projection(length_projection+1).Massflow_Tau_pipe_s_out .* ...
    model.record.projection(length_projection+1).Tau_pipe_s_out;

model.record.projection(length_projection+1).h_pipe_r_in = ...
    k*model.record.projection(length_projection+1).Massflow_Tau_pipe_r_in .* ...
    model.record.projection(length_projection+1).Tau_pipe_r_in;

model.record.projection(length_projection+1).h_pipe_r_out = ...
    k*model.record.projection(length_projection+1).Massflow_Tau_pipe_r_out .* ...
    model.record.projection(length_projection+1).Tau_pipe_r_out;











%%

Cal_alpha_beta();
% % aux_M_alpha aux_h_alpha
for t = 1:num_heatperiod
    for i = 1:Num_aux
        if t+1-i <= 0
            % % aux_M_alpha
            model.record.projection(length_projection+1).aux_M_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,:);
            % % aux_h_alpha
            model.record.projection(length_projection+1).aux_h_pipe_s_in_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,:);
            model.record.projection(length_projection+1).aux_h_pipe_r_in_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,:);
        elseif t+1-i >= 1
            % % aux_M_alpha
            model.record.projection(length_projection+1).aux_M_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.projection(length_projection+1).Massflow(t+1-i,:);
            % % aux_h_alpha
            model.record.projection(length_projection+1).aux_h_pipe_s_in_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.projection(length_projection+1).h_pipe_s_in(t+1-i,:);
            
            model.record.projection(length_projection+1).aux_h_pipe_r_in_alpha(i,:,t) = ...
                model.record.projection(length_projection+1).aux_alpha(i,:,t) .* ...
                model.record.projection(length_projection+1).h_pipe_r_in(t+1-i,:);
        end
    end
end

% % aux_M_beta aux_h_beta
for t = 1:num_heatperiod
    for i = 1:Num_aux
        if  t+1-i <= 0
            % % aux_M_beta
            model.record.projection(length_projection+1).aux_M_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.Massflow(t+num_initialtime+1-i,:);
            % % aux_h_beta
            model.record.projection(length_projection+1).aux_h_pipe_s_in_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,:);
            model.record.projection(length_projection+1).aux_h_pipe_r_in_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.solution(end).solution.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,:);
            
            %%
        elseif t+1-i >= 1
            % % aux_M_beta
            model.record.projection(length_projection+1).aux_M_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.projection(length_projection+1).Massflow(t+1-i,:);
            % % aux_h_beta
            model.record.projection(length_projection+1).aux_h_pipe_s_in_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.projection(length_projection+1).h_pipe_s_in(t+1-i,:);
            
            model.record.projection(length_projection+1).aux_h_pipe_r_in_beta(i,:,t) = ...
                model.record.projection(length_projection+1).aux_beta(i,:,t) .* ...
                model.record.projection(length_projection+1).h_pipe_r_in(t+1-i,:);
        end
    end
end

%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end
end