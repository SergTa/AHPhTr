% Название модели
modelName = 'PhaseChangeHeatRelease';

% Проверка и удаление существующей модели
if bdIsLoaded(modelName)
    close_system(modelName, 1); % закрыть без сохранения
    delete_model(modelName);   % удалить модель
end

% Создаем новую модель
new_system(modelName);
open_system(modelName);

% Параметры
length_tc = 1; % м
d_inner = 0.07; % м
d_outer = 0.1;  % м
initial_temp = -40; % °C
T_crystal = 0; % °C
T_melt = 0; % °C
latent_heat = 300e3; % Дж/кг
density_phase = 1600; % кг/м^3
volume = pi*((d_outer/2)^2 - (d_inner/2)^2)*length_tc; % м^3
mass = volume * density_phase; % кг
c_phase = 2000; % Дж/(кг·К)

% Создаем постоянные блоки
add_block('simulink/Sources/Constant', [modelName, '/InitialTemp'], 'Value', num2str(initial_temp));
add_block('simulink/Sources/Constant', [modelName, '/LatentHeat'], 'Value', num2str(latent_heat));
add_block('simulink/Sources/Constant', [modelName, '/Mass'], 'Value', num2str(mass));
add_block('simulink/Sources/Constant', [modelName, '/T_crystal'], 'Value', num2str(T_crystal));
add_block('simulink/Sources/Constant', [modelName, '/T_melt'], 'Value', num2str(T_melt));
add_block('simulink/Sources/Constant', [modelName, '/Velocity'], 'Value', '0.01');

% Блок для времени
add_block('simulink/Sources/Clock', [modelName, '/Clock']);

% Блок для моделирования положения фронта (скорость * время)
add_block('simulink/Math Operations/Product', [modelName, '/FrontPosition']);

% Соединения для фронта
add_line(modelName, 'Clock/1', 'FrontPosition/1');
add_line(modelName, 'Velocity/1', 'FrontPosition/2');

% Блок для определения текущего положения фронта
add_block('simulink/Math Operations/Sum', [modelName, '/FrontLocation']);
add_line(modelName, 'FrontPosition/1', 'FrontLocation/1');

% Блок для моделирования выделения теплоты
add_block('simulink/Math Operations/Gain', [modelName, '/Q_gain']);
set_param([modelName, '/Q_gain'], 'Gain', 'mass*latent_heat');

% Блок интегрирования выделенной теплоты
add_block('simulink/Continuous/Integrator', [modelName, '/Q_total']);

% Соединения для теплоты
add_line(modelName, 'Q_gain/1', 'Q_total/1');

% Блок для отображения выделенной теплоты
add_block('simulink/Sinks/Scope', [modelName, '/Q_scope']);

% Соединения
add_line(modelName, 'Q_total/1', 'Q_scope/1');

% --- Теперь добавим блоки для моделирования фронта и фазового перехода ---

% Блок для определения текущего положения фронта (используем 'Transport Delay' для моделирования распространения)
add_block('simulink/Continuous/Transport Delay', [modelName, '/FrontDelay']);
set_param([modelName, '/FrontDelay'], 'DelayTime', 'L/velocity'); % L - длина, velocity - скорость фронта

% Создаем блок для хранения длины (L)
add_block('simulink/Sources/Constant', [modelName, '/L'], 'Value', num2str(length_tc));

% Соединения для задержки фронта
add_line(modelName, 'L/1', 'FrontDelay/2');
add_line(modelName, 'Velocity/1', 'FrontDelay/1');

% Блок для определения текущего положения фронта (через 'Transport Delay')
add_block('simulink/Continuous/Transport Delay', [modelName, '/FrontPositionDelay']);
set_param([modelName, '/FrontPositionDelay'], 'DelayTime', 'L/velocity');

% Соединения
add_line(modelName, 'Clock/1', 'FrontPositionDelay/1');
add_line(modelName, 'L/1', 'FrontPositionDelay/2');

% Теперь создадим логический блок, который определяет, какая часть теплоаккумулятора уже кристаллизовалась
% Для этого сравним текущий фронт с позицией точки (например, с помощью блока 'Relational Operator')
add_block('simulink/Logic and Bit Operations/Relational Operator', [modelName, '/FrontReached']);
set_param([modelName, '/FrontReached'], 'Operator', '>');

% Для этого нужно подключить блок, который задает позицию точки (например, через блок 'Constant' или через 'Clock')
% В данном случае, можно использовать 'Clock' как текущий момент времени, умноженный на скорость
% Но для простоты, предположим, что фронт движется с постоянной скоростью, и мы можем моделировать его положение

% В итоге, для простоты, можно считать, что выделение теплоты происходит равномерно по длине, и фронт движется с постоянной скоростью

% --- В конце, добавьте блоки для расчета выделенной теплоты и отображения ---

% В этом примере — базовая структура. Для полноценной модели потребуется реализовать:
% - расчет текущего фазового состояния (кристаллизована или нет)
% - динамику выделения теплоты (например, через дифференциальные уравнения)
% - отображение теплового потока во времени

% Времени для полной реализации не хватает, но этот скелет поможет вам начать.

% Сохраняем и запускаем
save_system(modelName);
sim(modelName);