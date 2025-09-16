% Скрипт для автоматического создания модели в Simulink
modelName = 'HeatStorageModel';

% Создаем новую модель
new_system(modelName);
open_system(modelName);

% Параметры
params.T_air_in = -40;        % Начальная температура воздуха (°C)
params.T_phase_init = 20;     % Начальная температура теплоаккумулятора (°C)
params.h_inner = 10;          % Коэффициент теплообмена внутри (Вт/(м^2·К))
params.h_outer = 50;          % Коэффициент теплообмена с теплоаккумулятором (Вт/(м^2·К))
params.A_inner = pi * 0.07 * 1;  % Площадь внутренней поверхности (м^2)
params.A_outer = pi * 0.1 * 1;   % Площадь внешней поверхности (м^2)
params.m_air = 1.2 * pi * (0.07/2)^2 * 1; % Масса воздуха (кг)
params.c_air = 1005;          % Теплоемкость воздуха (Дж/(кг·К))
params.m_phase = pi * ((0.1/2)^2 - (0.07/2)^2) * 1 * 1600; % масса теплоаккумулятора (кг)
params.c_phase = 2000;        % Теплоемкость теплоаккумулятора (Дж/(кг·К))
params.T_air_in = -40;        % Входная температура воздуха (°C)
params.T_phase_init = 20;     % Начальная температура теплоаккумулятора (°C)

% Создаем блоки
add_block('simulink/Sources/Constant', [modelName, '/T_air_in'], 'Value', num2str(params.T_air_in));
add_block('simulink/Sources/Constant', [modelName, '/T_phase_init'], 'Value', num2str(params.T_phase_init));
add_block('simulink/Sources/Constant', [modelName, '/h_inner'], 'Value', num2str(params.h_inner));
add_block('simulink/Sources/Constant', [modelName, '/h_outer'], 'Value', num2str(params.h_outer));
add_block('simulink/Sources/Constant', [modelName, '/A_inner'], 'Value', num2str(params.A_inner));
add_block('simulink/Sources/Constant', [modelName, '/A_outer'], 'Value', num2str(params.A_outer));
add_block('simulink/Sources/Constant', [modelName, '/m_air'], 'Value', num2str(params.m_air));
add_block('simulink/Sources/Constant', [modelName, '/c_air'], 'Value', num2str(params.c_air));
add_block('simulink/Sources/Constant', [modelName, '/m_phase'], 'Value', num2str(params.m_phase));
add_block('simulink/Sources/Constant', [modelName, '/c_phase'], 'Value', num2str(params.c_phase));

% Блок для температуры воздуха (состояние)
add_block('simulink/Continuous/Integrator', [modelName, '/T_air']);
set_param([modelName, '/T_air'], 'InitialCondition', num2str(params.T_air_in));

% Блок для температуры теплоаккумулятора (состояние)
add_block('simulink/Continuous/Integrator', [modelName, '/T_phase']);
set_param([modelName, '/T_phase'], 'InitialCondition', num2str(params.T_phase_init));

% Теплопередача из теплоаккумулятора в теплообменник
add_block('simulink/Math Operations/Product', [modelName, '/Q_phase']);
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_phase']);
add_block('simulink/Math Operations/Gain', [modelName, '/Gain_phase']);
set_param([modelName, '/Gain_phase'], 'Gain', 'h_outer*A_outer');

% Разница температур теплоаккумулятора и теплообменника
add_block('simulink/Math Operations/Sum', [modelName, '/Delta_T_phase']);
set_param([modelName, '/Delta_T_phase'], 'Inputs', '+-');

% Теплопередача из теплообменника в воздух
add_block('simulink/Math Operations/Product', [modelName, '/Q_air']);
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_air']);
add_block('simulink/Math Operations/Gain', [modelName, '/Gain_air']);
set_param([modelName, '/Gain_air'], 'Gain', 'h_inner*A_inner');

% Разница температур теплообменника и воздуха
add_block('simulink/Math Operations/Sum', [modelName, '/Delta_T_air']);
set_param([modelName, '/Delta_T_air'], 'Inputs', '+-');

% Обновление температуры воздуха
add_block('simulink/Math Operations/Divide', [modelName, '/dT_air']);
set_param([modelName, '/dT_air'], 'Numerator', 'Q_air');
set_param([modelName, '/dT_air'], 'Denominator', 'm_air*c_air');

% Обновление температуры теплоаккумулятора
add_block('simulink/Math Operations/Divide', [modelName, '/dT_phase']);
set_param([modelName, '/dT_phase'], 'Numerator', 'Q_phase');
set_param([modelName, '/dT_phase'], 'Denominator', 'm_phase*c_phase');

% Соединения
add_line(modelName, 'T_air_in/1', 'T_air/1');
add_line(modelName, 'T_phase_init/1', 'T_phase/1');

% Теплопередача из теплоаккумулятора
add_line(modelName, 'T_phase/1', 'Delta_T_phase/1');
add_line(modelName, 'T_heat_exchanger/1', 'Delta_T_phase/2');
add_line(modelName, 'Delta_T_phase/1', 'Gain_phase/1');
add_line(modelName, 'Gain_phase/1', 'Q_phase/1');

% Теплопередача воздуху
add_line(modelName, 'T_heat_exchanger/1', 'Delta_T_air/1');
add_line(modelName, 'T_air/1', 'Delta_T_air/2');
add_line(modelName, 'Delta_T_air/1', 'Gain_air/1');
add_line(modelName, 'Gain_air/1', 'Q_air/1');

% Обновление температуры воздуха
add_line(modelName, 'Q_air/1', 'dT_air/1');
add_line(modelName, 'dT_air/1', 'T_air/1', 'autorouting', 'on');

% Обновление температуры теплоаккумулятора
add_line(modelName, 'Q_phase/1', 'dT_phase/1');
add_line(modelName, 'dT_phase/1', 'T_phase/1', 'autorouting', 'on');

% Время
add_block('simulink/Sources/Clock', [modelName, '/Clock']);

% Запуск симуляции
set_param(modelName, 'StopTime', '600');

% Сохраняем и запускаем
save_system(modelName);
sim(modelName);