% Название модели
modelName = 'PhaseChangeHeatRelease';

% Создаем новую модель
new_system(modelName);
open_system(modelName);

% Параметры
length_tc = 1; % длина теплообменника, м
d_inner = 0.07; % внутренний диаметр, м
d_outer = 0.1;  % внешний диаметр, м
initial_temp = -40; % начальная температура, °C
T_crystal = 0; % температура кристаллизации, °C (пример)
T_melt = 0; % температура плавления, °C (пример)
latent_heat = 300e3; % теплота кристаллизации, Дж/кг (пример)
density_phase = 1600; % плотность теплоаккумулятора, кг/м^3
volume = pi*((d_outer/2)^2 - (d_inner/2)^2)*length_tc; % объем, м^3
mass = volume * density_phase; % масса, кг

% Создаем блоки
add_block('simulink/Sources/Constant', [modelName, '/InitialTemp'], 'Value', num2str(initial_temp));
add_block('simulink/Sources/Constant', [modelName, '/LatentHeat'], 'Value', num2str(latent_heat));
add_block('simulink/Sources/Constant', [modelName, '/Mass'], 'Value', num2str(mass));
add_block('simulink/Sources/Constant', [modelName, '/T_crystal'], 'Value', num2str(T_crystal));
add_block('simulink/Sources/Constant', [modelName, '/T_melt'], 'Value', num2str(T_melt));

% Блок для моделирования фронта кристаллизации (распространение вдоль длины)
% Используем Transport Delay для моделирования времени прохождения фронта
add_block('simulink/Continuous/Transport Delay', [modelName, '/FrontDelay']);
set_param([modelName, '/FrontDelay'], 'DelayTime', 'L/velocity'); % нужно задать скорость распространения фронта

% Блок для определения текущей температуры в точке
% Можно использовать блок Switch для моделирования фазового состояния
% и блоки для расчета выделяемой теплоты

% Блок для расчета выделения теплоты
% Q = m * L * dα/dt, где α - доля кристаллизации (от 0 до 1)
% Для простоты моделируем как интеграл по времени с учетом фронта

% Создаем блоки для моделирования
% (подробнее ниже)

% --- Далее идет построение цепи, соединений, настройка ---
% Для краткости здесь приведена схема, которую нужно реализовать:
%
% 1. Вход - начальная температура
% 2. Время прохождения фронта (через Delay)
% 3. Расчет текущего состояния кристаллизации (например, через логические блоки)
% 4. Расчет выделяемой теплоты: dQ/dt = m * L * dα/dt
% 5. Интегрирование для получения Q(t)
% 6. Вывод Q(t) на Scope

% Ниже — пример кода, создающего базовую структуру

% Создаем блок для моделирования фронта кристаллизации
add_block('simulink/Continuous/Transfer Fcn', [modelName, '/FrontTransferFcn']);
set_param([modelName, '/FrontTransferFcn'], 'Numerator', '1', 'Denominator', '1');

% Создаем блок для моделирования скорости фронта (например, постоянная скорость)
add_block('simulink/Sources/Constant', [modelName, '/Velocity'], 'Value', '0.01'); % м/с

% Создаем блок для умножения скорости на время для получения положения фронта
add_block('simulink/Math Operations/Product', [modelName, '/FrontPosition']);

% Создаем блок Clock
add_block('simulink/Sources/Clock', [modelName, '/Clock']);

% Создаем блок для умножения скорости на время
add_block('simulink/Math Operations/Product', [modelName, '/FrontPosition']);

% Соединяем Clock с первым входом умножителя
add_line(modelName, 'Clock/1', 'FrontPosition/1');

% Создаем блок для постоянной скорости фронта
add_block('simulink/Sources/Constant', [modelName, '/Velocity'], 'Value', '0.01');

% Соединяем скорость с вторым входом умножителя
add_line(modelName, 'Velocity/1', 'FrontPosition/2');

% Создаем блок для определения текущего положения фронта
add_block('simulink/Math Operations/Sum', [modelName, '/FrontLocation']);
add_line(modelName, 'FrontPosition/1', 'FrontLocation/1');

% Далее — расчет выделяемой теплоты
% Можно использовать блок 'Gain' для умножения m*L
add_block('simulink/Math Operations/Gain', [modelName, '/Q_gain']);
set_param([modelName, '/Q_gain'], 'Gain', 'mass*latent_heat');

% Интегратор для накопления теплоты
add_block('simulink/Continuous/Integrator', [modelName, '/Q_total']);

% Соединения
add_line(modelName, 'Q_gain/1', 'Q_total/1');

% Визуализация
add_block('simulink/Sinks/Scope', [modelName, '/Q_scope']);

add_line(modelName, 'Q_total/1', 'Q_scope/1');

% Настройка симуляции
set_param(modelName, 'StopTime', '600');

% Сохраняем и запускаем
save_system(modelName);
sim(modelName);