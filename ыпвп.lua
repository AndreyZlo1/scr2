--[[ PRACTICAL BASKETBALL v144 — Potassium/UNC — модуль для лоадера Syllinse ]]

-- Luraph macro prelude. Installed through STRING KEYS on the global env so a
-- bare macro token never appears in real code (that would abort Luraph). Raw,
-- every macro is an identity pass-through, so the same source runs unobfuscated
-- for testing; Luraph overrides them at build time. Only hot per-frame compute
-- (the trajectory/physics loops) is wrapped below — everything else stays
-- virtualized so the actual logic is not left readable.
do
  local _E = (getgenv and getgenv()) or _G
  if not _E["LPH_NO_VIRTUALIZE"] then
    local id = function(f) return f end
    local nop = function() end
    _E["LPH_NO_VIRTUALIZE"] = id
    _E["LPH_JIT"] = id
    _E["LPH_JIT_MAX"] = id
    _E["LPH_ENCFUNC"] = id
    _E["LPH_ENCSTR"] = function(s) return s end
    _E["LPH_CRASH"] = nop
  end
end

local VERSION = 144

local CFG = {

  Enabled   = true,

  -- Замерено по трём выборкам (21, 13 и 19 бросков): центр Perfect лежит на
  -- 1.5170, зоны Perfect и Good в чистых замерах не пересекаются
  -- (Perfect 1.5151..1.5188, Good от 1.5312). Диагностик bias независимо дал
  -- -0.0235 от прежней цели 1.5405, то есть ровно 1.5170.
  -- В v123 это значение уже стояло, но ВМЕСТЕ с заменой floor на округление
  -- при выборе тика — регрессию дал тик, и откат унёс заодно и цель.
  Target    = 1.5170,
  PingBase  = 0.0,
  PingCoef  = 0.94,

  PingMax   = 1.45,
  TargetMin = 0.15,
  RateFlat  = 3.05,

  UseFittedRate = true,

  RateMinN  = 4,

  RateLo    = 1.20,
  RateHi    = 4.50,

  TickRate    = 60,
  ResetBelow= 0.60,

  ArmWindow    = 0.60,
  -- Потолок ожидания сброса метра. Замер по 14 броскам: реальный сброс
  -- приходит на 0.22..0.54 с, а потолок 1.20 вместе с продлением на 0.10
  -- вытягивал удержание до 1.30 — и такой бросок гарантированно давал
  -- Very Late. 0.65 накрывает самый медленный случай с запасом.
  ArmWindowMax = 0.65,

  NoMeterGrace = 0.38,
  ClockCoef = 0.7572,
  ClockSlack= 0.15,
  SpinWindow= 0.020,
  StaleMax  = 0.25,
  PhaseSane = 0.60,

  MaxWait   = 1.05,
  -- Таймить ли данки и лэйапы наравне с бросками. Игра выставляет им те же
  -- вердикты Very Early / Very Late, значит тайминг у них есть.
  TimeDunks = true,
  -- Радиус, дальше которого персонажи игровой логике не интересны.
  -- Самый дальний порог в скрипте — Blatant.MaxDist = 120.
  NearRadius = 140,
  GreenFloor= 0.259,
  GreenMinOK= 0.315,

  Spoof = {
    Enabled = false,

    FakeDist = 12, PreTime = 0.030, HoldMax = 0.20,
    MinRealDist = 30, HoldUntilRegister = true,
    -- Не затягивать внутрь дуги, если бросок и так трёхочковый: FakeDist по
    -- умолчанию 12, то есть ближе линии в 23.5, и подмена превращала бы
    -- честную тройку в двойку. Ровно это выглядит как «спуф работает в
    -- радиусе кольца».
    KeepThree = true,
  },

  -- SMART 3PT — САМОСТОЯТЕЛЬНАЯ ФИЧА, А НЕ ГАЛКА ВНУТРИ СПУФА.
  -- Спуф дистанции и Smart 3PT решают разные задачи и тянут в разные стороны:
  -- спуф ведёт К кольцу (шире окно грина), Smart 3PT — ЗА дугу (больше очков).
  -- Раньше вторая жила внутри первой и без неё не включалась вовсе.
  S3 = {
    Enabled = false,
    -- Расстояние трёхочковой линии от кольца. Единственное, с чем сравнивают
    -- дистанцию до игрока. Разметку площадки скрипт меряет отдельно и только
    -- печатает в дампе, чтобы это число можно было выставить по факту.
    LineDist = 33.5,   -- дальше этого от кольца бросок считается тройкой
    Window  = 6.0,
    Extra   = 1.2,
    Hold    = true,
    HoldMax = 1.80,
  },

  Traj = {
    Enabled  = false,

    Duration = 2.0,   Samples = 48,

    PhysDuration = 2.4, PhysSamples = 64,
    Thick    = 2,     ZIndex = 5,
    ScoreRad = 1.9,
    MinSpeed = 16,
    HoldDist = 7,
    FlightHold = 0.20,

    SkipTeammates = false,
    Diag = true,

    FitSamples = 12,

    VelSmooth  = 0.35,

    VelJump    = 25,
    FitWindow  = 0.32,
    MinFitN    = 4,

    MaxSpeed   = 150,

    MapCheck   = true,
    Bounces    = 3,
    BounceKeep = 0.55,

    RayNear    = 14,
    RayBudget  = 24,

    RenderLag  = 0.05 + 1/65,

    PredCheck  = 0.30,

    MaxSlack   = 10,

    TagEvery   = 0.25,
    ScanEvery  = 3.0,
    ColorIn  = Color3.fromRGB(0, 255, 120),
    ColorOut = Color3.fromRGB(255, 70, 70),
    Marks    = true,
  },

  Grab = {
    Enabled   = false,

    GoalCheck = true,
    SkipOwn   = true,
    GoalRad   = 6.0,

    BlockRange= 7,

    RimAttackRad = 14,
    RimAttackCD  = 0.45,

    Catch        = true,

    SkipMakes    = true,

    PreCatch     = true,
    PreArcTail   = 1.6,
    PreCatchMax  = 45,

    CatchAhead   = 2.4,
    CatchFitN    = 3,
    -- УПРЕЖДЕНИЕ ПО ДУГЕ. Встать ровно в точку прихода мяча значит поставить
    -- всё на один хват: не взяли — мяч улетел дальше, а мы стоим позади него.
    -- Идём НЕМНОГО ВПЕРЁД по той же дуге, тогда промах по хвату оставляет нас
    -- на пути мяча, а не за спиной. Доля от участка дуги после точки прихода.
    CatchLead = 0.35,
    CatchStand   = 1.5,
    CatchBody    = 3.5,

    -- Насколько НЕ ХВАТАЕТ времени, но мы всё равно бежим. Было 1.20, и в
    -- дампе 2396 отказов "no reachable catch point" уложились в 1.20..1.48:
    -- то есть мы вставали ровно на границе. Оценка консервативна, мяч
    -- отскакивает, а по расстоянию нас всё равно ограничивает CatchMaxRun.
    CatchChase   = 2.50,
    -- ДАЛЬШЕ ЭТОГО ЗА МЯЧОМ НЕ БЕЖИМ ВООБЩЕ.
    -- CatchChase меряет нехватку ВРЕМЕНИ и на далёком мяче легко проходит,
    -- из-за чего скрипт перехватывал управление ради заведомо безнадёжной
    -- пробежки. Расстояние — честный предел: не добежать, значит не мешаем.
    CatchMaxRun  = 22,
    CatchFaceRate= 30,
    RimCatch     = true,
    RimCatchRad  = 16,
    RimCatchJump = 6.0,
    RimCatchRun  = 26,

    HoopRad   = 32,

    LeadTime  = 0.18,

    UseCones  = false,
    BlockCone = 0.5,
    FaceCone  = 0.35,
    BlockStandoff = 2.5,

    ShootTime = 0.44,

    MinCommit = 0.12,

    BallUp    = 3.0,

    ArcEffect = 0.35,

    -- Границы взяты из самой игры: база типа броска 0.675..1.05
    -- (Basketball_ModuleScript) плюс поправка пакета -0.10..+0.25.
    -- Прежние 0.05..1.05 существовали только потому, что мы принимали
    -- поправку за итог, и выученное значение спокойно уезжало к 0.33.
    ArcEffMin = 0.55,
    ArcEffMax = 1.35,

    JumpLagFallback = 2.0,
    LagMin   = 0.06,
    LagMax   = 0.80,

    PingUp    = 0.5,
    JumpEarly = 0.040,

    Anticipate  = true,

    RimStandoff = 3.5,
    RimStandoffMin = 2.0,
    RimStandoffMax = 12.0,
    Sprint    = true,
    SpeedPad  = 0.85,
    FaceBall  = true,
    JumpCD    = 0.45,

    RimGuard   = true,

    PastHoop   = 0.12,

    RimZone    = 12,

    RimDrop    = 1.5,

    MinAbove   = 3.2,

    CloseShot  = 10,

    ChaseSlack = 0.25,

    PreShot    = true,

    FaceWindow = 0.70,
    ReachXZ    = 6.0,

    OnlyInMatch = true,

    ShotHold   = 1.60,
    ArmReach   = 3.5,

    NoJumpDy   = 2.2,

    GroundWait = 0.90,

    ApexMin    = 0.4,
    ApexMax    = 16.0,
    ApexMinN   = 2,
    ApexGuess  = 1.5,
    ApexWatch  = 1.2,

    ReachMin   = 4.0,
    ReachMax   = 16.0,
    ReachSet   = 0,
    LookAhead  = 1.20,

    GuardFitN  = 2,

    CampRad    = 14,
  },

  Blatant = {
    Enabled  = false,
    Gap      = 2.2,
    RiseY    = 1.5,
    HoopRad  = 30,
    MaxDist  = 120,


    OnWindup  = true,
    -- СКОЛЬКО ДЕРЖИМ ПОДМЕНУ ПОЗИЦИИ. Одна настройка на все ветки.
    -- Раньше их было две и они расходились: обычный вход резался HoldFrames
    -- (6 кадров, 0.1 с), а вход по windup — WindupMax, то есть 1.2 СЕКУНДЫ.
    -- Отсюда «долго удерживает». Контест начисляется на регистрации броска,
    -- пары кадров достаточно.
    HoldTime  = 0.12,
    -- СТОЙКА ДЕРЖИТСЯ ДОЛЬШЕ ПОДМЕНЫ ПОЗИЦИИ, И ЭТО РАЗНЫЕ ВЕЩИ.
    -- HoldTime — сколько кадров держим подменённую позицию, её надо
    -- показать серверу на регистрации и сразу убрать. Стойка же работает
    -- всё время, пока соперник целится: контест копится, пока защитник
    -- рядом и в стойке. Держать её те же 0.12 с бессмысленно.
    StanceTime = 0.80,
    DunkRise  = 3.0,   -- добавка к высоте, когда он идёт данком или лэйапом
    Cooldown = 0.30,
    -- ПОРОГ ПО МЕТРУ ВРАГА. Раньше вход был только по Action = rim/windup, а
    -- обычный джампшот попадает туда лишь на релизе — то есть всегда поздно.
    -- Метр соперника реплицируется (meterOffset у его модели), и по нему видно
    -- бросок ЗАРАНЕЕ: на этой доле от его релиза и выходим накрывать.
    MeterTrigger = 0.45,
    HoldG    = true,
    Restore  = true,
  },

  Defense = {

    Enabled  = false,

    Mode     = "Auto",

    HoopRad  = 40,
    HoldG    = true,
    Engage   = 16.5,
    Speed    = 25,

    SnapDist = 3.0,
    Deadzone = 0.6,

    StandShoot = 3.5,
    StandBase  = 6.0,
    LeadLat    = 0.1,
    LeadLatDrib= 0.2,
    LeadFwd    = 0.1,
    BlowbyDot  = 0.4,
    BlowbySpeed= 9,
    BlowbyGap  = 8.5,
    BlowbyAhead= 6.5,
    SprintDist = 4.1,
    StaminaMin = 20,
    -- Насколько широко обходить подопечного, когда он на пути к точке защиты.
    WalkAround = 3.0,
  },

  Stamina = { Enabled = false, Value = 100 },

  Move = {
    Speed      = { Enabled = false, Value = 22 },
    Fly        = { Enabled = false, Speed = 60 },

    -- НЕ ГНУТЬ КУРС У КОЛЬЦА.
    -- Любое искривление направления пишет forwardValue (мы обязаны его
    -- пересчитать, иначе анимация и скорость разъедутся). А игра по нему
    -- решает две вещи: Movement:142 требует forwardValue > 0.35 для спринта,
    -- UpdateSpeed:101 при forwardValue < 0.5 делит скорость на 1.35.
    -- Разгонный данк без скорости не выбирается, и сервер отдаёт лэйап.
    -- Внутри этого радиуса от кольца курс не трогаем вообще.
    RimFree    = 14,
    Slip = {
      Enabled = false,
      Angle   = 18,
      LookDeg = 35,
      StartMul = 2.0,
      SkipNoContact = true,

      Mode        = "Default",

      ReactRadius = 24,
      StanceRange = 15,
      KeepGap     = 11,
      StanceWeight= 1.8,

      Open        = 15,
      OpenWeight  = 3.0,
      LaneWeight  = 2.0,
      InputWeight = 0.8,
      StepOut     = 11,
      FeintStep   = 15,

      MaxTurn     = 70,

      Commit      = 0.35,
      CommitTime  = 0.28,

      FoeSpeedStance = 17.5,
      FoeSpeedBase   = 15.0,
      OurSpeed       = 15.0,

      React          = 0.18,

      PressRise    = 1.6,
      PressFall    = 1.2,

      ZoneRad     = 24,
      ZoneSlack   = 4,
      ZoneWeight  = 2.0,

      LookFake    = true,
      LookOff     = 35,
      LookRate    = 90,
    },

    -- Shooting: двигаться и спринтить, пока идёт УЖЕ ОТПУЩЕННЫЙ бросок.
    -- Пока удар держат, вводом его можно отменить, поэтому окно открывается
    -- только после релиза (атрибут ReleasedShot).
    Strafe     = { Enabled = false, Side = true, Back = true, Shooting = false },
    AutoSprint = { Enabled = false },

    Sprint     = { Enabled = false, Bonus = 3.35 },
    NoStun     = { Enabled = false },
    NoCooldown = { Enabled = false },

    NoClip     = { Enabled = false },
    -- ПРОХОД СКВОЗЬ СОПЕРНИКОВ. Collision_ModuleScript:114 пропускает весь
    -- контактный блок, если CanCollide выключен у ЛЮБОЙ из сторон, а :136 он
    -- же двигает наш HumanoidRootPart при перекрытии. Гасим CanCollide на
    -- частях соперников локально — сервер эти части не читает, толчок
    -- и разделение перестают срабатывать.
    -- All: снимать коллизию СО ВСЕХ игроков, а не только с соперников по
    -- нашему матчу. В парке на площадке рядом стоят чужие матчи, isEnemy для
    -- них ложь, и мы в них врезались. В дампе это 27 человек в ростере при
    -- ghostParts = 76, то есть обработано было около пяти персонажей.
    GhostFoes  = { Enabled = false, All = true, Radius = 22 },

    Preset = {
      Enabled = false,

      -- ПОЛНЫЙ НАБОР ИЗ ИГРЫ.
      -- Movement_ModuleScript:444..510 присваивает CurrentMovementType ровно
      -- десять значений, и столько же модулей лежит в Inside_Movement/Types.
      -- Трёх не хватало: GoKart, Sit и TipOff. Множители у них по единице —
      -- поведение не меняется, пока игрок сам не тронет ползунок.
      Mul = { Base = 1.0, Guard = 1.0, Post = 0.6, Boxout = 0.8,
              BoxoutPlayer = 1.0, Call = 0.8, Retreat = 0.8,
              GoKart = 1.0, Sit = 1.0, TipOff = 1.0 },

      Turn = { Base = 0, Guard = 0, Post = 0, Boxout = 0,
               BoxoutPlayer = 0, Call = 0, Retreat = 0,
               GoKart = 0, Sit = 0, TipOff = 0 },

      FlattenAll = false,
    },

    Moves = {
      Enabled = false,
      Bind    = {},

    },
  },

  Zero = {
    Enabled   = false,
    Stand     = true,
    KillSprint= true,
    FromStart = true,
    Lead      = 0.20,
    Tail      = 0.10,
  },

  AntiDef = {
    Enabled = false,
    -- ── ПОСТОЯННЫЙ УВОД (работает всегда, не только на броске) ──
    Keep    = 7.0,     -- защитник ближе этого подмешивается в твой курс
    Push    = 0.70,    -- насколько сильно подмешивается
    OnlyBall= true,
    PushOn  = false,   -- постоянный увод: отдельный выключатель
    Stance  = true,

    PreShot   = true,
    Mode      = "Legit",
    Dribble     = false,
    DribbleCombo= "X",     -- Dribbling.Input.X = StepBack на обе руки
    DribbleCD   = 1.2,
    BackTPMax   = 12,

    -- ── ОТШАГ ПЕРЕД БРОСКОМ (режим Legit) ──
    -- React запускает отшаг, StopAt его завершает. Это РАЗНЫЕ числа: одно
    -- отвечает на «стоит ли уходить», второе на «уже хватит».
    React     = 14.0,  -- защитник ближе этого — уходим
    StopAt    = 20.0,  -- дальше этого уже не мешает, стоп
    StepTime  = 0.22,  -- сколько длится отшаг
    Speed     = 24,    -- скорость отшага, задаётся напрямую
    LegitFace = true,

    FaceRate  = 200,
    FaceSmooth = 1.0,

    BoostFrames = 3,
    StanceWeight = 2.0,
    MaxShift  = 10,
    MaxSwing  = 80,
    SwingStep = 5,
  },

  Face = { Mode = "Enemy", Rate = 9.0, Smooth = 0.35 },

  Move2 = {
    Enabled  = false,
    HoopRad  = 32,
    Standoff = 4.0,
    RimStand = 5.5,
    Margin   = 1.20,

    MaxRun   = 1.10,

    HoldTol  = 3.0,

    Stance   = false,
    StanceRad= 6.0,
    Steal    = false,
    StealRad = 4.0,
    StealCD  = 1.2,
    Sprint   = true,
  },

  Stealth = {

    BackoffAfterServerCF = 0.35,
    HideStack = true,
  },

  Debug = { Folder = "PracticalBasketball", File = "dump.json",
            Copy = false, Verdict = true },
}

local cloneref  = cloneref or function(o) return o end
local Players   = cloneref(game:GetService("Players"))
local RunService= cloneref(game:GetService("RunService"))
local UIS       = cloneref(game:GetService("UserInputService"))
local RS        = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local Stats     = game:GetService("Stats")
local CollSvc   = cloneref(game:GetService("CollectionService"))
local LP        = Players.LocalPlayer

local filtergc       = filtergc
local hookfunction   = hookfunction
local restorefunction= restorefunction
local writefile    = writefile or function() end
local makefolder   = makefolder
local getconnections = getconnections
local isfolder     = isfolder
local setclipboard = setclipboard or function() end

local Mt = {
  GetAttribute   = game.GetAttribute,
  FindFirstChild = game.FindFirstChild,
  GetFullName    = game.GetFullName,
  GetChildren    = game.GetChildren,
  GetDescendants = game.GetDescendants,
  InvokeServer   = nil,
}

local G = getgenv and getgenv() or _G
if G.__PB and G.__PB.unload then pcall(G.__PB.unload) end

local PBX = { AE = { pkgs=nil, types=nil, at=-math.huge } }

local HUB = { conns={}, running=true, gen=0, pending=false, bypass=false, gs={},
              shots={}, stats={}, foreign={reg=0,green=0,feed=0},
              mVal=nil, mAt=nil, mSeq=0, regSeq=0, greenVal=nil,
              lastJump=0, shootAt={} }
G.__PB = HUB

function PBX.gs(k, v)
  local e = HUB.gs[k]
  if not e then e = { n = 0 }; HUB.gs[k] = e end
  e.n = e.n + 1
  if type(v) == "number" then
    e.lo = e.lo and math.min(e.lo, v) or v
    e.hi = e.hi and math.max(e.hi, v) or v
  end
end

local function track(c) table.insert(HUB.conns, c); return c end

-- ОДНА ОШИБКА НЕ ДОЛЖНА УБИВАТЬ ПОДПИСКУ НАВСЕГДА.
-- Кадровые тики висят на Heartbeat напрямую: любая ошибка внутри рвёт
-- соединение, и фича молча перестаёт существовать до перезапуска скрипта.
-- Именно так выглядит "перехват вообще не прыгает" при единственной
-- арифметической ошибке где-то в глубине тика. Оборачиваем и ЗАПОМИНАЕМ
-- текст: он уйдёт в дамп, и место станет видно сразу.
function PBX.guarded(name, fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      HUB.errN = (HUB.errN or 0) + 1
      local e = HUB.errs; if not e then e = {}; HUB.errs = e end
      local key = name .. ": " .. tostring(err)
      e[key] = (e[key] or 0) + 1
      HUB.lastErr, HUB.lastErrAt = key, os.clock()
    end
  end
end

-- КЛЮЧ-INSTANCE УДЕРЖИВАЕТ УДАЛЁННУЮ МОДЕЛЬ ОТ СБОРКИ.
-- Эти таблицы индексируются персонажами. Чистка в них есть, но срабатывает
-- только для тех, кто ещё в charsList(): вышедший из игры или переродившийся
-- игрок остаётся ключом навсегда и тянет за собой всю свою модель. Слабые
-- ключи снимают вопрос целиком — запись исчезает вместе с персонажем.
local function weakKeys(t) return setmetatable(t, { __mode = "k" }) end
-- Одна функция на запись CanCollide вместо замыкания на КАЖДУЮ деталь в
-- покадровых циклах Ghost Opponents и NoClip.
function PBX.setCC(x, v) x.CanCollide = v end
weakKeys(HUB.shootAt)

-- СЧЁТЧИК КАДРОВ ДЛЯ ПОКАДРОВЫХ КЭШЕЙ.
-- Подписки регистрируются в порядке объявления, поэтому эта стоит самой первой
-- и успевает поднять номер до всех остальных. Двигают его обе фазы: игровые
-- UpdateMoveDirection и UpdateVelocity вызываются движком между ними, и по
-- одному Heartbeat кэш прожил бы лишний такт.
HUB.frame = 0
local function bumpFrame() HUB.frame += 1 end
track(RunService.Heartbeat:Connect(bumpFrame))
track(RunService.RenderStepped:Connect(bumpFrame))

HUB.notify = nil
local function notify(msg)
  if HUB.notify then pcall(HUB.notify, "Practical Basketball", tostring(msg)) end
end

local REPORT = {}
local function rep(fmt, ...)
  local ok, line = pcall(string.format, fmt, ...)
  REPORT[#REPORT+1] = ok and line or tostring(fmt)
end
local LOG = {}
local function dbg(tag, msg)
  if os.clock() - (HUB.dbgAt or 0) < 1.5 then return end
  HUB.dbgAt = os.clock()
  LOG[#LOG+1] = ("%.1f %s: %s"):format(os.clock(), tostring(tag), tostring(msg))
  if #LOG > 200 then table.remove(LOG, 1) end
end

local Rem      = RS:WaitForChild("Aero"):WaitForChild("AeroRemoteServices")
local InputSvc = Rem:WaitForChild("InputService")
local MeterSvc = Rem:WaitForChild("MeterService")
local IfaceSvc = Rem:WaitForChild("InterfaceService")

local PhysSvc = Rem:FindFirstChild("PhysicsService")
local R = {
  Shoot  = InputSvc:WaitForChild("Shoot"),
  Jump   = InputSvc:WaitForChild("Jump"),
  Sprint = InputSvc:WaitForChild("Sprint"),
  Move   = InputSvc:WaitForChild("MoveDirection"),
  MReg   = MeterSvc:WaitForChild("RegisterPacket"),
  MUnreg = MeterSvc:WaitForChild("UnregisterPacket"),
  MUpd   = MeterSvc:WaitForChild("UpdateGreenWindow"),
  Feed   = IfaceSvc:FindFirstChild("ShowFeedback"),
  SetCF  = PhysSvc and PhysSvc:FindFirstChild("SetCFrame"),
  HoldG  = InputSvc:FindFirstChild("HoldG"),
  Steal  = InputSvc:FindFirstChild("Steal"),
  Drib   = InputSvc:FindFirstChild("Dribble"),
}

Mt.FireServer = R.Shoot.FireServer

pcall(function()
  local f = Mt.FindFirstChild
  local n = f(cloneref(game:GetService("ReplicatedStorage")), "Aero")
  n = n and f(n, "AeroRemoteServices")
  n = n and f(n, "PlayerService")
  n = n and f(n, "GetStats")
  if n then Mt.InvokeServer = n.InvokeServer end
end)

HUB.serverCF = 0
if R.SetCF then
  track(R.SetCF.OnClientEvent:Connect(function() HUB.serverCF = os.clock() end))
end
local function physAllowed()
  return (os.clock() - HUB.serverCF) > CFG.Stealth.BackoffAfterServerCF
end

local function sAttr(i,n)
  if not i then return nil end
  local ok,v = pcall(Mt.GetAttribute,i,n)
  if ok and v ~= nil then return v end
  local ok2,v2 = pcall(function()
    local f = Mt.FindFirstChild(i, "Attributes")
    if not f then return nil end
    local o = Mt.FindFirstChild(f, n)
    if not o then return nil end
    return o.Value
  end)
  return ok2 and v2 or nil
end
local function sChild(i,n) if not i then return nil end local ok,v=pcall(Mt.FindFirstChild,i,n) return ok and v or nil end
local function sFull(i)    if not i then return nil end local ok,v=pcall(Mt.GetFullName,i)      return ok and v or nil end
-- ЧИТАТЕЛИ СВОЙСТВ БЕЗ АЛЛОКАЦИЙ.
-- По всему файлу стоял оборот "pcall с анонимной функцией на чтение": она
-- создаётся ЗАНОВО на каждый вызов и захватывает объект апвэлью, то есть
-- это аллокация замыкания. В кадровых циклах по всем игрокам набегали тысячи
-- мусорных объектов в секунду и постоянное давление на сборщик. Здесь функция
-- на каждое имя свойства создаётся ОДИН раз за всю сессию и потом переиспользуется.
local RDR = setmetatable({}, { __index = function(t, k)
  local f = function(x) return x[k] end
  rawset(t, k, f)
  return f
end })
-- Горизонтальная маска встречается в файле больше сотни раз, почти вся —
-- внутри кадровых циклов по игрокам. Считаем её один раз.
local FLAT = Vector3.new(1,0,1)
local function posOf(inst)
  if not inst then return nil end
  local ok,p = pcall(RDR.Position, inst)
  return ok and p or nil
end

HUB.myChar = nil
local function chr()
  if HUB.myChar and HUB.myChar.Parent then return HUB.myChar end
  local f = sChild(Workspace, "Characters")
  local c = f and sChild(f, LP.Name)
  HUB.myChar = c
  return c or LP.Character
end
local function isMine(character)
  if character == nil then return false end
  if character == chr() then return true end
  local ok,nm = pcall(RDR.Name, character)
  return ok and nm == LP.Name
end
local function proxyPart() return sChild(Workspace, "ProxyCharacter") end

local function holdRelease()
  local c = chr(); if not c then return end
  pcall(function() c:SetAttribute("CFrame", nil) end)
end

local function tpProxy(pc, cf)
  if not (pc and cf) then return false end
  local ok = pcall(function()
    pc.CFrame = cf
    local bp = pc:FindFirstChild("BodyPosition")
    if bp then bp.Position = cf.Position end
    local mv = pc:FindFirstChild("MovementVelocity")
    if mv then mv.Velocity = Vector3.new(0,0,0) end
    local ph = pc:FindFirstChild("Physics")
    local ap = ph and ph:FindFirstChild("AlignPosition")
    if ap and ap.Mode == Enum.PositionAlignmentMode.OneAttachment then
      ap.Position = cf.Position
    end
    pc.AssemblyLinearVelocity = Vector3.new(0,0,0)
  end)
  return ok
end
-- ПОЗИЦИЯ СЕБЯ СЧИТАЛАСЬ ЗАНОВО НА КАЖДЫЙ ВЫЗОВ.
-- Тридцать точек вызова, часть из них в кадровых тиках и внутри циклов: каждый
-- раз FindFirstChild плюс чтение свойства. Внутри одного кадра ответ не
-- меняется, поэтому держим его до следующего кадра. Ключ — счётчик кадров, а
-- не время: он не зависит от частоты и не даёт заглянуть в чужой кадр.
local SP = { p = nil, f = -1 }
local function selfPos()
  if SP.f == HUB.frame then return SP.p end
  SP.p = posOf(sChild(chr(), "HumanoidRootPart")) or posOf(proxyPart())
  SP.f = HUB.frame
  return SP.p
end

local function lookAtCF(pos, at, keepRotFrom)
  if not pos or pos ~= pos then return nil end
  local rot = nil
  if keepRotFrom then
    local okc, cur = pcall(RDR.CFrame, keepRotFrom)
    if okc and cur then rot = cur - cur.Position end
  end
  if at then
    local flat = Vector3.new(at.X - pos.X, 0, at.Z - pos.Z)
    if flat.Magnitude > 0.05 then
      local cf = CFrame.new(pos, Vector3.new(at.X, pos.Y, at.Z))
      local lv = cf.LookVector
      if lv == lv then return cf end
    end
  end
  return rot and (rot + pos) or CFrame.new(pos)
end

local charComp = nil
local function findCharComp()
  if charComp and rawget(charComp, "lastValidHeight") ~= nil then return charComp end
  if not filtergc then return nil end
  local ok, t = pcall(filtergc, "table",
    { Keys = { "lastValidHeight", "ProxyCharacter", "MainMovementPosition" } }, true)
  charComp = (ok and type(t) == "table") and t or nil
  return charComp
end
local function groundLevel()
  local c = findCharComp()
  if not c then return nil end
  local v = rawget(c, "lastValidHeight")
  return (type(v) == "number" and v == v) and v or nil
end

HUB.pingItem   = nil
HUB.pingVal    = 0.05
HUB.pingSource = "init"
HUB.pingFails  = 0

local function resolvePingItem()
  if HUB.pingItem then return HUB.pingItem end
  local ok, item = pcall(function()
    return Stats.Network.ServerStatsItem["Data Ping"]
  end)
  if ok and item then HUB.pingItem = item end
  return HUB.pingItem
end

local function refreshPing()
  local item = resolvePingItem()
  if item then
    local ok, v = pcall(function() return item:GetValue() end)
    if ok and type(v)=="number" and v > 0 then
      HUB.pingVal, HUB.pingSource = v/1000, "DataPing"
      return
    end
  end

  local ok2, v2 = pcall(function() return LP:GetNetworkPing() end)
  if ok2 and type(v2)=="number" and v2 > 0 then
    HUB.pingVal, HUB.pingSource = v2, "GetNetworkPing"
    HUB.pingFails += 1
    return
  end

  HUB.pingSource = "stale"
  HUB.pingFails += 1
end
refreshPing()
task.spawn(function()
  while HUB.running do refreshPing(); task.wait(0.2) end
end)

local function dataPing() return HUB.pingVal end

local function srvNow()
  local base
  local okb, v = pcall(Mt.GetAttribute, Workspace, "SERVER_START_TIME")
  if okb and type(v) == "number" then base = v end
  if not base then return nil end
  local okn, t = pcall(function() return Workspace:GetServerTimeNow() end)
  if not okn or type(t) ~= "number" then return nil end
  return t - base
end

local meterConn, meterChar
local function bindMeter()
  local c = chr()
  if not c or c == meterChar then return end
  local ok,sig = pcall(function() return c:GetAttributeChangedSignal("meterOffset") end)
  if not ok or not sig then return end
  if meterConn then pcall(function() meterConn:Disconnect() end) end
  meterChar = c
  meterConn = sig:Connect(function()
    local v = sAttr(c, "meterOffset")
    local r
    if typeof(v)=="Vector2" then
      local ax,ay = math.abs(v.X), math.abs(v.Y); r = (ay>ax) and ay or ax
    elseif type(v)=="number" then r = math.abs(v) end
    if r then HUB.mVal, HUB.mAt, HUB.mSeq = r, os.clock(), HUB.mSeq+1 end
  end)
end
-- РАНЬШЕ ЗДЕСЬ БЫЛ track(meterConn) ВНУТРИ bindMeter.
-- Он выполняется на каждую смену персонажа, и HUB.conns копил по мёртвой
-- записи на респавн. Регистрируем один снос, он всегда рвёт актуальную связь.
track({ Disconnect = function()
  if meterConn then pcall(function() meterConn:Disconnect() end) end
  meterConn, meterChar = nil, nil
end })
-- РАЗ В СЕКУНДУ БЫЛО СЛИШКОМ РЕДКО.
-- Всё окно между подменой модели персонажа и переподключением сигнал метра
-- молчит, а бросок укладывается в полсекунды — то есть целый бросок мог
-- пройти вслепую. Сама проверка стоит одно сравнение с закэшированным
-- персонажем, так что учащение почти ничего не стоит.
task.spawn(function() while HUB.running do bindMeter(); task.wait(0.25) end end)

local function meterPoll()
  local v = sAttr(chr(), "meterOffset")
  if typeof(v)=="Vector2" then
    local ax,ay = math.abs(v.X), math.abs(v.Y); return (ay>ax) and ay or ax
  elseif type(v)=="number" then return math.abs(v) end
  return nil
end

HUB.shooting = weakKeys({})

track(R.MReg.OnClientEvent:Connect(function(character, meterType, greenVal)
  if character then HUB.shooting[character] = os.clock() end
  if not isMine(character) then HUB.foreign.reg += 1; return end
  if type(greenVal)=="number" then HUB.greenVal = greenVal end
  HUB.regSeq += 1; HUB.meterType = meterType
end))
track(R.MUnreg.OnClientEvent:Connect(function(character)
  if character then HUB.shooting[character] = nil end
end))
track(R.MUpd.OnClientEvent:Connect(function(character, greenVal)
  if not isMine(character) then HUB.foreign.green += 1; return end
  if type(greenVal)=="number" then HUB.greenVal = greenVal end
end))

function PBX.shotAge(c)
  local t = c and HUB.shooting[c]
  if not t then return nil end
  local age = os.clock() - t
  if age > CFG.Grab.ShotHold then HUB.shooting[c] = nil; return nil end
  return age
end

local PK = { at = 0, side = nil, court = nil, ref = nil, names = {}, n = 0, src = "?" }
function PK.refs(court)

  local out = {}
  local g = sChild(court, "Game");        if g then out[#out+1] = g end
  local h1 = sChild(court, "HalfCourt1"); if h1 then out[#out+1] = h1 end
  local h2 = sChild(court, "HalfCourt2"); if h2 then out[#out+1] = h2 end
  return out
end
function PK.sideOf(ref, name)
  local pl = sChild(sChild(ref, "Attributes"), "Players")
  if not pl then return nil end
  for side = 1, 2 do
    local f = sChild(pl, "Team" .. side)
    if f and sChild(f, name) then return side end
  end
  return nil
end
function PK.roster(ref)
  local out, n = {}, 0
  local pl = sChild(sChild(ref, "Attributes"), "Players")
  if not pl then return out, n end
  for side = 1, 2 do
    local f = sChild(pl, "Team" .. side)
    if f then
      local ok, kids = pcall(Mt.GetChildren, f)
      if ok then
        for _, k in ipairs(kids) do out[k.Name] = side; n = n + 1 end
      end
    end
  end
  return out, n
end
function PK.scan()
  local now = os.clock()
  if now - PK.at < 1.0 then return end
  PK.at = now
  local courts = sChild(sChild(Workspace, "Map"), "Courts")
  if not courts then PK.src = "no Map.Courts"; return end
  local ok, kids = pcall(Mt.GetChildren, courts)
  if not ok then PK.src = "Courts unreadable"; return end
  local me = LP.Name
  for _, court in ipairs(kids) do
    for _, ref in ipairs(PK.refs(court)) do
      local side = PK.sideOf(ref, me)
      if side then

        if PK.court ~= court or PK.ref ~= ref then
          PK.dirty = true
          HUB.myGoalCache, HUB.defendCache = nil, nil
        end
        PK.court, PK.ref, PK.side = court, ref, side
        PK.names, PK.n = PK.roster(ref)
        PK.src = ("%s.%s Team%d (%d in match)"):format(court.Name, ref.Name, side, PK.n)
        return
      end
    end
  end

  if PK.court then PK.dirty = true; HUB.myGoalCache, HUB.defendCache = nil, nil end
  PK.court, PK.ref, PK.side, PK.names, PK.n = nil, nil, nil, {}, 0
  PK.src = "not on any court roster"
end
track(RunService.Heartbeat:Connect(PK.scan))

function PBX.inMatch()
  if PK.side ~= nil then return true end
  local me = chr(); if not me then return false end
  return (sAttr(me, "InGame") == true) or (sAttr(me, "OnCourt") == true)
end

function PBX.matchLive()
  if not PBX.inMatch() then return false end
  local c = chr(); if not c then return false end
  local a = sAttr(c, "Action")
  if a == "Inbounding" or a == "AwaitingCelebration" then return false end
  if sAttr(c, "FreeThrow") == true or sAttr(c, "WatchingFreeThrow") == true then
    return false
  end
  local ref = PK.ref
  if ref then
    local ok, started = pcall(function() return ref:GetAttribute("StartedGame") end)
    if ok and started ~= nil then return started == true end
  end

  return true
end

local hoopCache, hoopCacheAt, hoopSrc = {}, 0, "?"
local function hoopGoalPart(model)
  return model and sChild(model, "Goal") or nil
end
local function courtHoopNames()
  local myCourt = sAttr(chr(), "CourtNumber")
  local courts = sChild(sChild(Workspace, "Map"), "Courts")
  if not courts then return nil end
  local ok, kids = pcall(Mt.GetChildren, courts)
  if not ok then return nil end
  local mode = nil
  pcall(function() mode = Workspace:GetAttribute("Gamemode") end)
  local names = {}

  for _, court in ipairs(kids) do
    if (PK.court and court == PK.court)
       or ((not PK.court) and sAttr(court, "CourtNumber") == myCourt) then
      if mode == "Park" or mode == "Plaza" then
        local lst = sAttr(court, "Hoops")
        if type(lst) == "string" then
          for _, nm in ipairs(string.split(lst, ",")) do
            nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
            if nm ~= "" then names[nm] = true end
          end
        end
      else
        local ok2, sub = pcall(function() return court:GetChildren() end)
        if ok2 then
          for _, c2 in ipairs(sub) do
            if c2.Name ~= "Items" then
              local nm = sAttr(c2, "Hoop")
              if type(nm) == "string" and nm ~= "" then names[nm] = true end
            end
          end
        end
      end
    end
  end
  return next(names) and names or nil
end
local function hoopList()
  local now = os.clock()

  if PK.dirty then PK.dirty = false; hoopCache = {} end
  if (now - hoopCacheAt) < 5 and #hoopCache > 0 then return hoopCache end
  hoopCacheAt = now
  local hoops = sChild(Workspace, "Hoops")
  if not hoops then hoopCache = {}; hoopSrc = "no Hoops folder"; return hoopCache end
  local out = {}

  local names = courtHoopNames()
  if names then
    for nm in pairs(names) do
      local p = posOf(hoopGoalPart(sChild(hoops, nm)))
      if p then out[#out+1] = p end
    end
    if #out > 0 then hoopSrc = "court CourtNumber" end
  end

  if #out == 0 then
    local ok, list = pcall(function() return hoops:GetChildren() end)
    if ok then
      for _, m in ipairs(list) do
        local p = posOf(hoopGoalPart(m))
        if p then out[#out+1] = p end
      end
    end
    hoopSrc = "all hoops (court unknown)"
  end
  hoopCache = out
  return hoopCache
end

local charCache, charCacheAt = {}, 0
-- ПОЛНЫЙ СПИСОК ВСЕХ ПЕРСОНАЖЕЙ СЕРВЕРА.
-- Нужен ровно двум местам: выгрузке ростера и подсчёту чужих матчей. Игровой
-- логике он вреден — см. charsList ниже.
local function charsAll()
  local now = os.clock()
  if now - charCacheAt < 0.25 then return charCache end
  charCacheAt = now
  local f = sChild(Workspace, "Characters")
  if not f then charCache = {}; return charCache end
  local ok, kids = pcall(Mt.GetChildren, f)
  local out = {}
  if ok then
    for _, c in ipairs(kids) do
      if c.Name ~= "Racks" and c.Name ~= "InvisCharacter"
         and sChild(c, "HumanoidRootPart") then
        out[#out+1] = c
      end
    end
  end
  charCache = out
  return charCache
end

-- ТОЛЬКО ТЕ, КТО РЯДОМ, И ЭТО ГЛАВНАЯ ЭКОНОМИЯ КАДРА.
-- В парке Workspace.Characters содержит ВЕСЬ сервер: в разобранном дампе это
-- 27 человек при шести в нашем матче, соседние площадки стоят в 200-300
-- студах. По этому списку в коде проходит 21 цикл, значительная часть каждый
-- кадр, и каждый лишний персонаж стоит FindFirstChild плюс чтения атрибутов.
-- Ни одна функция не смотрит дальше Blatant.MaxDist = 120, поэтому всё, что
-- дальше порога, не может повлиять ни на что. Заодно это чинит голосование за
-- кольцо: голоса чужих матчей больше не мешают.
PBX.near = { list = {}, at = 0 }
local function charsList()
  local now = os.clock()
  local NC = PBX.near
  if now - NC.at < 0.20 then return NC.list end
  local R = CFG.NearRadius
  if not (R and R > 0) then NC.list = charsAll(); NC.at = now; return NC.list end
  local me = selfPos()
  if not me then NC.list = charsAll(); NC.at = now; return NC.list end
  NC.at = now
  local out, r2 = {}, R * R
  for _, c in ipairs(charsAll()) do
    local q = posOf(sChild(c, "HumanoidRootPart"))
    if q then
      local dx, dz = q.X - me.X, q.Z - me.Z
      if dx*dx + dz*dz <= r2 then out[#out+1] = c end
    end
  end
  NC.list = out
  return out
end

PBX.PASS_WAIT = { CatchingPass = true, AwaitingPass = true,
                  CatchingLob = true, PassTransition = true }
function PBX.passTo(ball)
  if not ball then return nil end
  for _, c in ipairs(charsList()) do
    if PBX.PASS_WAIT[sAttr(c, "Action")] and sAttr(c, "TargetBasketball") == ball then
      return c
    end
  end
  return nil
end

-- Свой мяч спрашивают около шести раз за кадр из разных систем: хук движения
-- сам по себе трижды. Кэш на один кадр и только для СЕБЯ — чужих персонажей
-- проверяют по одному разу, там кэш только мешал бы.
local function hasBall(c)
  if c ~= nil and c == HUB.myChar and HUB.hbFrame == HUB.frame then return HUB.hbVal end
  local v = sAttr(c, "Basketball")
  local got = not (v == nil or v == false)
  if c ~= nil and c == HUB.myChar then HUB.hbFrame, HUB.hbVal = HUB.frame, got end
  return got
end

PBX.SHOT_PROJ = { Shooting = true, FreeThrow = true }

PBX.SHOT_RIM  = { Dunking = true, Layup = true, ContactLayup = true, ClutchLayup = true }

PBX.SHOT_WIND = { Gathering = true, ContactPlant = true }

-- ДЕЙСТВИЯ, ПРИ КОТОРЫХ ИГРА ВООБЩЕ НЕ СЧИТАЕТ КОНТАКТ.
-- Collision_ModuleScript:9 держит этот список, а :114 при попадании в него
-- пропускает ВЕСЬ цикл расталкивания. То есть в эти моменты сквозь соперника
-- можно идти напрямую, и гнуть курс не только незачем — вредно: увод стоит
-- скорости и роняет forwardValue.
PBX.NO_CONTACT = { Dunking = true, ContactLayup = true, CatchingPass = true,
                   Passing = true, Shooting = true,
                   -- Не из списка игры, но по смыслу то же: на проходе и на
                   -- рывке гнуть курс — значит мешать самому себе.
                   BlowingBy = true, BlowbyPush = true }
function PBX.contactOff()
  local a = sAttr(chr(), "Action")
  return a ~= nil and PBX.NO_CONTACT[a] == true
end

-- ЧТО ИГРА САМА СЧИТАЕТ «МЯЧ У ИГРОКА».
-- Mobile_ModuleScript:75 решает, осмысленно ли нажатие удара, так:
--   Basketball ИЛИ Action из { CatchingPass, Dunking, Shooting, CatchingLob }
-- То есть атрибут Basketball — лишь ОДИН из признаков. На данке игрок сначала
-- выбрасывает мяч, и в руках его уже нет: Basketball = false. Наш хук стоял
-- ровно на этом атрибуте и данки пропускал МИМО конвейера целиком — в дампе
-- это 8 вердиктов при 2 записях броска, шесть штук ушли нетаймленными.
PBX.BALL_LIKE = { CatchingPass = true, Dunking = true, Shooting = true,
                  CatchingLob = true, ContactLayup = true, ClutchLayup = true }
function PBX.hasBallLike(c)
  if hasBall(c) then return true end
  local a = sAttr(c, "Action")
  return a ~= nil and PBX.BALL_LIKE[a] == true
end

-- Бросок «живой» — это не только Action == "Shooting". Данк и лэйап тоже
-- броски, и цикл взвода обязан ждать их так же.
function PBX.liveShotAct(a)
  if a == nil then return false end
  return PBX.SHOT_PROJ[a] == true or PBX.SHOT_RIM[a] == true
end

function PBX.shotKind(c)
  local a = sAttr(c, "Action")
  if a == nil then return nil end
  if PBX.SHOT_PROJ[a] then return "projectile" end
  if PBX.SHOT_RIM[a] then return "rim" end
  if PBX.SHOT_WIND[a] then return "windup" end
  return nil
end
function PBX.isShot(c) return PBX.shotKind(c) ~= nil end

local function isEnemy(c)
  if not c or c == chr() then return false end
  if PK.side then
    local s = PK.names[c.Name]
    if s then return s ~= PK.side end
    return false
  end
  local me = chr()
  local myI, thI = sAttr(me,"TeamIndex"), sAttr(c,"TeamIndex")
  if type(myI)=="number" and type(thI)=="number" and myI ~= 0 and thI ~= 0 then
    return myI ~= thI
  end
  local myH, thH = sAttr(me,"HomeTeam"), sAttr(c,"HomeTeam")
  if type(myH)=="boolean" and type(thH)=="boolean" then return myH ~= thH end
  local myT, thT = sAttr(me,"Team"), sAttr(c,"Team")
  if type(myT)=="number" and type(thT)=="number" and myT ~= 0 and thT ~= 0 then
    return myT ~= thT
  end
  return true
end

-- ОДИН СНИМОК ВРАГОВ НА КАДР ВМЕСТО ПЯТИ.
-- Постоянный увод в хуке движения, отшаг Legit, подбор точки для телепорта,
-- накрытие и защита — каждый независимо шёл по charsList() и на КАЖДОГО
-- игрока делал isEnemy (несколько чтений атрибутов), FindFirstChild корня,
-- чтение Position и чтение HoldingG. При десяти игроках это сотни вызовов на
-- кадр, повторяющих одну и ту же работу. Считаем один раз за кадр.
-- Массив и записи в нём переиспользуются, поэтому после прогрева снимок не
-- аллоцирует вообще ничего: важно, потому что зовётся он из кадровых путей.
PBX.foes = { f = -1, n = 0, pool = {} }
local function foeSnap()
  local F = PBX.foes
  if F.f == HUB.frame then return F.pool, F.n end
  local n = 0
  local wantG = CFG.AntiDef.Stance == true
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      local q = posOf(sChild(c, "HumanoidRootPart"))
      if q then
        n += 1
        local e = F.pool[n]
        if not e then e = {}; F.pool[n] = e end
        e.c, e.p = c, q
        -- Стойку читаем только если она вообще кому-то нужна.
        e.g = wantG and (sAttr(c, "HoldingG") == true) or false
        -- Действие и мяч кладём СЮДА, а не перечитываем в каждом цикле.
        -- Тик перехвата проходил список соперников трижды (строки 4975, 5043,
        -- 5202) и на каждом проходе заново дёргал те же два атрибута. При
        -- шести соперниках это 36 лишних чтений в кадр, при 27 — под сотню.
        e.act  = sAttr(c, "Action")
        e.ball = sAttr(c, "Basketball") == true
      end
    end
  end
  -- Хвост пула обязан отпускать ссылки: если врагов стало меньше, записи
  -- сверху продолжали бы держать ушедшего персонажа до конца сессии.
  for i = n + 1, #F.pool do
    local e = F.pool[i]
    if e and e.c == nil then break end
    if e then e.c, e.p, e.g = nil, nil, nil end
  end
  F.n, F.f = n, HUB.frame
  return F.pool, n
end

local function isMate(c)
  if not c or c == chr() then return false end
  if PK.side then
    local s = PK.names[c.Name]
    return s ~= nil and s == PK.side
  end
  return isEnemy(c) == false
end

local CV = setmetatable({}, { __mode = "k" })
local function charVel(c)
  if not c then return Vector3.new() end
  local p = posOf(sChild(c, "HumanoidRootPart"))
  if not p then return Vector3.new() end
  local now = os.clock()
  local st = CV[c]
  if not st then CV[c] = { t = now, p = p, v = Vector3.new() }; return Vector3.new() end
  local dt = now - st.t
  if dt >= 0.04 then
    local raw = (p - st.p) / dt

    st.v = st.v:Lerp(raw, 0.4)
    st.t, st.p = now, p
  end
  return st.v
end

local function goalPosOf(c)
  local g = sAttr(c, "Goal")
  local t = typeof(g)
  if t == "Instance" then return posOf(g)
  elseif t == "CFrame" then return g.Position
  elseif t == "Vector3" then return g end
  return nil
end
HUB.myGoalCache = nil

local function ourGoalPos()
  local p = goalPosOf(chr())
  if p then HUB.myGoalCache = p; return p end

  local list = hoopList()
  if #list == 1 then HUB.myGoalCache = list[1]; return list[1] end

  local votes, bestP, bestN = {}, nil, 0
  for _, c in ipairs(charsList()) do
    if isMate(c) then
      local q = goalPosOf(c)
      if q then
        local key = ("%d_%d"):format(math.floor(q.X), math.floor(q.Z))
        local v = (votes[key] or 0) + (hasBall(c) and 3 or 1)
        votes[key] = v
        if v > bestN then bestP, bestN = q, v end
      end
    end
  end
  if bestP then HUB.myGoalCache = bestP; return bestP end
  return HUB.myGoalCache
end

-- ПОКАДРОВЫЙ МЕМО: ЗВАЛИ 23 РАЗА, ЧАСТЬ ИЗ НИХ ПО НЕСКОЛЬКУ РАЗ ЗА КАДР.
-- Запасная ветка этой функции сама идёт по всем игрокам, то есть каждый лишний
-- вызов — ещё один полный обход. Внутри кадра ответ не меняется.
local function hoopWeDefend()
  if HUB.hwdFrame == HUB.frame then return HUB.hwdVal end
  local v = PBX.hoopWeDefendRaw()
  HUB.hwdFrame, HUB.hwdVal = HUB.frame, v
  return v
end

function PBX.hoopWeDefendRaw()
  local list = hoopList()
  if #list == 1 then
    HUB.defendCache = list[1]
    HUB.defendSrc = "single-hoop court (both teams score here)"
    return list[1]
  end
  local og = ourGoalPos()

  if og and #list >= 2 then
    local best, bd
    for _, p in ipairs(list) do
      local d = (p - og).Magnitude
      if not bd or d > bd then best, bd = p, d end
    end
    if best and bd and bd > 20 then
      HUB.defendCache, HUB.defendSrc = best, "opposite of our own Goal"
      return best
    end
  end

  local votes, bestP, bestN = {}, nil, 0
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      local p = goalPosOf(c)

      if p and ((not og) or (p - og).Magnitude > 20) then
        local key = ("%d_%d"):format(math.floor(p.X), math.floor(p.Z))
        local v = (votes[key] or 0) + (hasBall(c) and 3 or 1)
        votes[key] = v
        if v > bestN then bestP, bestN = p, v end
      end
    end
  end
  if bestP then
    HUB.defendCache, HUB.defendSrc = bestP, ("enemy Goal vote (%d)"):format(bestN)
    return bestP
  end
  HUB.defendSrc = "cache"
  return HUB.defendCache
end

local function defendGoalPos(shooter)

  local one = hoopList()
  if #one == 1 then HUB.defendCache = one[1]; return one[1] end

  if shooter then
    local p = goalPosOf(shooter)
    local og = ourGoalPos()
    local ours = (shooter == chr()) or isMate(shooter)
    if p and (ours or ((not og) or (p - og).Magnitude > 20)) then
      HUB.defendCache = p; return p
    end
  end

  local og = ourGoalPos()
  local list = hoopList()
  if og and #list > 0 then
    local best, bd
    for _, p in ipairs(list) do
      local d = (p - og).Magnitude
      if not bd or d > bd then best, bd = p, d end
    end
    if best and bd and bd > 20 then HUB.defendCache = best; return best end
  end

  return HUB.defendCache
end

local function nearestHoop(from)
  local best, bd
  for _, p in ipairs(hoopList()) do
    local d = (p-from).Magnitude
    if not bd or d < bd then best, bd = p, d end
  end
  return best
end

local function pingCorr(R, pEff)
  R = R or CFG.RateFlat
  local p = pEff or dataPing()
  local c = R * CFG.PingCoef * (p - CFG.PingBase)
  return math.clamp(c, -CFG.PingMax, CFG.PingMax)
end

local function effTarget(R, pEff)
  return math.max(CFG.Target - pingCorr(R, pEff), CFG.TargetMin)
end

local zeroUntil, zeroSprintSent = 0, false
local function zeroHold(sec)
  local Z = CFG.Zero
  if not Z.Enabled then return end

  if os.clock() > zeroUntil then zeroSprintSent = false end
  zeroUntil = math.max(zeroUntil, os.clock() + (sec or 0))
  if Z.KillSprint and not zeroSprintSent then
    zeroSprintSent = true

    HUB.bypass = true; pcall(Mt.FireServer, R.Sprint, false); HUB.bypass = false
  end
end
local function zeroRelease()
  zeroUntil = 0
  zeroSprintSent = false
end

local function zeroKeep(t0)
  local Z = CFG.Zero
  if not (Z.Enabled and Z.FromStart) then return end
  local want = os.clock() + Z.Tail + 0.06

  if t0 then want = math.min(want, t0 + CFG.MaxWait + Z.Tail) end
  zeroUntil = math.max(zeroUntil, want)
end
local function zeroActive()
  if not (CFG.Zero.Enabled and CFG.Zero.Stand) then return false end
  if os.clock() >= zeroUntil then return false end
  -- ОТШАГ AntiDefense ГЛАВНЕЕ ЗАМОРОЗКИ, И ЭТО НЕ КОМПРОМИСС.
  -- Две фичи требуют противоположного: Force Zero Spread — стоять весь бросок,
  -- Anti Defense Legit — отойти во время него. Заморозка стоит ПЕРВОЙ веткой
  -- хука движения и делает return, поэтому ветка отшага не выполнялась вообще:
  -- в дампе это «legit retreat: moved 0.0 stds» при работе 242 мс.
  -- Побеждает отшаг: он убирает контест, а контест портит бросок сильнее, чем
  -- ненулевая скорость. Заморозка вернётся сама, как только отшаг закончится.
  if HUB.antiStepUntil and os.clock() < HUB.antiStepUntil then return false end
  return true
end

local stopSteerSoft

function PBX.pendHold(g)
  HUB.pending, HUB.pendingGen = true, g

  HUB.pendingUntil = os.clock() + CFG.MaxWait + CFG.Zero.Tail + 0.5
end
function PBX.pendClear()
  HUB.pending, HUB.pendingGen, HUB.pendingUntil = false, nil, nil
end

-- БРОСОК СЧИТАЕТСЯ ЖИВЫМ И ДО ОТВЕТА СЕРВЕРА.
-- Прежний признак был "pendActive() или Action == Shooting". Между нажатием
-- и ответом сервера (это целый пинг) не выполняется ни то, ни другое: при
-- выключенном Auto Green ожидание снимается сразу, а Action ещё пустой. В эту
-- щель успевал влезть Contest Shooter: он шлёт Shoot=true, а через 0.12 с
-- Shoot=false — и чужой релиз отпускал СВОЙ бросок игрока на метре 0.24.
-- Снаружи это ровно "скрипт моментально скидывает мяч". Помним момент
-- нажатия и держим окно на пинг с запасом.
function PBX.shotBusy()
  if PBX.pendActive() then return true end
  if sAttr(chr(), "Action") == "Shooting" then return true end
  local t = HUB.shotPressAt
  if t and (os.clock() - t) < ((dataPing() or 0.1) + 0.6) then return true end
  return false
end

function PBX.pendActive()
  if not HUB.pending then return false end
  if HUB.pendingGen ~= HUB.gen then PBX.pendClear(); return false end
  if HUB.pendingUntil and os.clock() > HUB.pendingUntil then PBX.pendClear(); return false end
  return true
end

function PBX.ensureReleased(g)
  task.spawn(function()
    local tEnd = os.clock() + 2.5
    local resent, heldSince = 0, nil
    while HUB.running and HUB.gen == g and os.clock() < tEnd and resent < 4 do
      local c = chr()
      local holding = c and sAttr(c, "Action") == "Shooting"
                        and sAttr(c, "ReleasedShot") == false
      if holding then
        heldSince = heldSince or os.clock()
        if os.clock() - heldSince > 0.25 then
          HUB.bypass = true
          pcall(Mt.FireServer, R.Shoot, { Shoot = false })
          HUB.bypass = false
          resent += 1
          HUB.releaseResent = (HUB.releaseResent or 0) + 1
          heldSince = nil
        end
      else
        heldSince = nil
      end
      RunService.Heartbeat:Wait()
    end
  end)
end

local function scheduleRelease(g, t0, startArgs)
  local ss, w = nil, 0
  repeat
    ss = sAttr(chr(), "ShotSpeed")
    if type(ss)=="number" and ss>0 then break end
    RunService.Heartbeat:Wait(); w = os.clock()-t0
  until w>0.15 or HUB.gen~=g
  if HUB.gen~=g or not HUB.running then

    if HUB.pendingGen == g then PBX.pendClear() end
    return
  end
  if type(ss)~="number" or ss<=0 then ss = 1.8 end

  local armed, tArmed = false, nil
  local armDeadline = t0 + CFG.ArmWindow

  local sawMeter = false
  local seq0 = HUB.mSeq

  local start0 = sAttr(chr(), "ShotStartTime")
  -- ПАМПФЕЙК ЛОВИМ ПО ПЕРЕХОДУ, А НЕ ПО СОСТОЯНИЮ.
  -- GatherType — ЗАЛИПАЮЩИЙ серверный атрибут: после одного пампфейка он так
  -- и остаётся "Pumpfake" до следующего гатера. Проверка «равен Pumpfake»
  -- поэтому срабатывала на ПЕРВОЙ же итерации каждого следующего броска, шла
  -- в ветку dead и мгновенно слала Shoot=false — то есть скрипт отпускал удар
  -- сразу, как только игрок начал удерживать. В дампе это видно по числам:
  -- shotDead = 10 и ровно десять пропущенных MeterIndex, причём пропуски
  -- начинаются после №42 и дальше идут через один. Отсюда и ощущение, что
  -- проблема нарастает со временем: она включается после первого пампфейка
  -- и больше не выключается. Запоминаем значение на старте и реагируем
  -- только на СМЕНУ на Pumpfake.
  local gt0 = sAttr(chr(), "GatherType")
  local tSrvStart = nil
  local sawShooting, goneFrames, dead = false, 0, false
  while HUB.running and HUB.gen==g do
    local r = meterPoll()
    local fresh = (HUB.mSeq ~= seq0) and HUB.mAt ~= nil and HUB.mAt >= t0
    if fresh then sawMeter = true end
    -- ВЗВОД ТОЛЬКО ПО СВЕЖЕМУ ЧТЕНИЮ.
    -- meterPoll читает атрибут напрямую и в покое отдаёт ОСТАТОК прошлого
    -- броска: по дампу это 0.24, что ниже ResetBelow = 0.60. Поэтому взвод
    -- случался на нулевой миллисекунде (в записях armAt = 0.0001), tArmed
    -- вставал на t0, и clockTarget уезжал на полсекунды раньше срока. Если
    -- при этом метр так и не пришёл, бросок уходил по часам с вердиктом
    -- Very Early. Свежесть определяем тем же способом, что и в основном
    -- цикле: значение должно прийти СИГНАЛОМ ПОСЛЕ старта броска.
    if r and r < CFG.ResetBelow and fresh then armed = true; tArmed = os.clock(); break end
    local el = os.clock() - t0
    local act = sAttr(chr(), "Action")
    if not tSrvStart then
      local sCur = sAttr(chr(), "ShotStartTime")
      if sCur ~= nil and sCur ~= start0 then tSrvStart = os.clock() end
    end
    if PBX.liveShotAct(act) then
      sawShooting, goneFrames = true, 0
    elseif sawShooting then
      goneFrames += 1
      if goneFrames >= 2 then dead = true; HUB.deadWhy = "action left Shooting"; break end
    end
    -- Второй рубеж: настоящий пампфейк метр НЕ наполняет. Если сигнал метра
    -- уже приходил после старта, значит бросок живой, и что бы ни лежало в
    -- атрибуте — обрывать его нельзя.
    local gtNow = sAttr(chr(), "GatherType")
    if gtNow == "Pumpfake" and gt0 ~= "Pumpfake" and not sawMeter then
      dead = true; HUB.deadWhy = "pump fake"; break
    end
    if el < CFG.ArmWindowMax then
      if not tSrvStart then

        armDeadline = math.max(armDeadline, os.clock() + 0.10)
      elseif PBX.liveShotAct(act)
         and (sawMeter or (os.clock() - tSrvStart) < CFG.NoMeterGrace) then
        armDeadline = math.max(armDeadline, os.clock() + 0.10)
      end
    end
    if os.clock() > armDeadline then break end
    if zeroKeep then zeroKeep(t0) end
    RunService.Heartbeat:Wait()
  end
  HUB.lastArmSawMeter = sawMeter
  HUB.lastSrvStartLag = tSrvStart and (tSrvStart - t0) or nil

  if dead then
    HUB.shotDead = (HUB.shotDead or 0) + 1
    HUB.lastDeadAt = os.clock()
    if HUB.pendingGen == g then PBX.pendClear() end
    HUB.bypass = true
    pcall(Mt.FireServer, R.Shoot, { Shoot = false })
    HUB.bypass = false
    zeroRelease()
    PBX.ensureReleased(g)
    return
  end
  if HUB.gen~=g or not HUB.running then

    if HUB.pendingGen == g then PBX.pendClear() end
    return
  end

  local effT = effTarget()

  local clockBase = tSrvStart or t0
  local clockTarget = armed and ((tArmed or t0) + effT/CFG.RateFlat + CFG.ClockSlack)
                            or  (clockBase + math.max(CFG.ClockCoef/ss, CFG.ArmWindow + 0.10))

  local lastR, lastT, rate = nil, nil, nil
  local sn,sx,sy,sxx,sxy = 0,0,0,0,0
  local seenSeq = HUB.mSeq
  local firedBy, phaseAtFire, tgtUsed = "clock", nil, effT
  local tArm, nSamples, firstR, firstAt = os.clock(), 0, nil, nil
  local meterTrace = {}

  local tickPeriod = 1/CFG.TickRate

  while HUB.running and HUB.gen==g do
    local now = os.clock()
    local r, rAt
    if HUB.mSeq ~= seenSeq and HUB.mVal then
      local at = HUB.mAt
      if at and at >= t0 then r, rAt, seenSeq = HUB.mVal, at, HUB.mSeq
      else seenSeq = HUB.mSeq end
    end
    -- СТРАХОВКА НА МЁРТВЫЙ СИГНАЛ МЕТРА.
    -- Подписка висит на КОНКРЕТНОЙ модели персонажа и переподключается раз в
    -- секунду. Пока модель подменилась, а переподключение ещё не случилось,
    -- сигнал молчит, и в дампе это записи с samples = 0 и пустым trace:
    -- бросок уходит вслепую по часам, вердикт Very Early (шесть штук за
    -- сессию). Опрос атрибута напрямую даёт то же значение, просто с
    -- точностью до кадра вместо точного времени события. Поэтому включаем
    -- его ТОЛЬКО когда сигнала не было вовсе: у здорового броска первый
    -- отсчёт приходит максимум на 0.28 с, так что порог 0.35 их не задевает
    -- и точность подгонки скорости не портит.
    if not r and nSamples == 0 and (now - t0) > 0.35 then
      local pr = meterPoll()
      if pr and pr ~= lastR then
        r, rAt = pr, now
        HUB.meterPolled = (HUB.meterPolled or 0) + 1
      end
    end

    if r and not armed then
      armed = true; tArmed = rAt or now
      clockTarget = math.max(clockTarget,
        (rAt or now) + (effT - r)/CFG.RateFlat + CFG.ClockSlack)
    end

    if r and (lastR == nil or r ~= lastR) then

      local x = (rAt or now) - t0
      sn+=1; sx+=x; sy+=r; sxx+=x*x; sxy+=x*r
      if sn >= CFG.RateMinN then
        local den = sn*sxx - sx*sx
        if den > 1e-9 then
          local sl = (sn*sxy - sx*sy)/den
          if sl > CFG.RateLo and sl < CFG.RateHi then rate = sl end
        end
      end
      lastR, lastT = r, (rAt or now)
      HUB.lastRate = rate and (math.floor(rate*100)/100) or "fallback"
      nSamples += 1
      if not firstR then firstR, firstAt = r, (rAt or now) end
      if #meterTrace < 40 then
        meterTrace[#meterTrace+1] = { dt = math.floor(((rAt or now)-t0)*1e4)/1e4, r = r }
      end
    end

    if lastR and (now - lastT) <= CFG.StaleMax then

      local Rt  = (CFG.UseFittedRate and rate) or CFG.RateFlat

      local tgt = effTarget(Rt)

      local need  = lastT + (tgt - lastR)/Rt

      if CFG.Zero.Enabled and not CFG.Zero.FromStart then
        local eta = need - now
        if eta <= CFG.Zero.Lead then
          zeroHold(math.max(eta, 0) + CFG.Zero.Tail + 0.05)
        end
      end

      if tickPeriod and tickPeriod > 0.008 then
        -- Метр дискретен: за тик он прыгает на step = rate*tickPeriod (0.046..0.055
        -- по замерам). Раньше тик выбирался по ВРЕМЕНИ пересечения (floor), из-за
        -- чего мы систематически били мимо на половину шага — 0.023..0.028 при
        -- ширине окна Perfect около 0.02. Выбираем тик, чьё ЗНАЧЕНИЕ ближе всего
        -- к цели, и уже в его середину целимся.
        -- floor, а НЕ округление. Округление пробовалось в v123: оно сдвигает
        -- выстрел на полтика позже, и замер это подтвердил — srvMeter вырос с
        -- 1.533 до 1.556, а доля Perfect упала с 73% до 17%. Тик берём тот, в
        -- котором цель пересекается, и целимся в его середину.
        local k = math.floor((need - lastT)/tickPeriod)
        need = lastT + (k + 0.5)*tickPeriod
      end
      local phase = lastR + Rt*(now - lastT)

      if phase > tgt then
        firedBy = "phase_late"
        phaseAtFire = phase
        tgtUsed = tgt
        break
      end
      if phase >= 0 and phase <= (tgt + CFG.PhaseSane)
         and (need - now) <= CFG.SpinWindow then
        while os.clock() < need do end
        firedBy = "phase"
        phaseAtFire = lastR + Rt*(os.clock() - lastT)
        tgtUsed = tgt
        break
      end
    end

    if now >= clockTarget then

      local alive = lastR and (now - lastT) < 0.10

      local Rc = (CFG.UseFittedRate and rate) or CFG.RateFlat
      local below = lastR and (lastR + Rc*(now-lastT)) < effTarget(Rc)
      if alive and below and (now - t0) < CFG.MaxWait then
        clockTarget = now + 0.05
      else
        firedBy = armed and "clock_armed" or "clock_nometer"
        phaseAtFire = lastR
        break
      end
    end
    if now - t0 > CFG.MaxWait then firedBy = "timeout"; break end
    if zeroKeep then zeroKeep(t0) end
    RunService.Heartbeat:Wait()
  end

  if HUB.gen~=g or not HUB.running then

    if HUB.pendingGen == g then PBX.pendClear() end
    return
  end
  PBX.pendClear()
  HUB.bypass = true
  pcall(Mt.FireServer, R.Shoot, { Shoot = false })
  HUB.bypass = false
  PBX.ensureReleased(g)

  if CFG.Zero.Enabled then
    zeroHold(CFG.Zero.Tail)
    task.delay(CFG.Zero.Tail + 0.02, zeroRelease)
  end

  local hp = selfPos()
  local og = ourGoalPos()
  local rec = {

    hold = os.clock()-t0, firedBy = firedBy, phase = phaseAtFire, target = tgtUsed,
    armAt = math.floor((tArm-t0)*1e4)/1e4,
    armed = armed, meterAtFire = lastR,
    lastReadAge = lastT and math.floor((os.clock()-lastT)*1e4)/1e4 or nil,
    ping = dataPing(), pingSource = HUB.pingSource,
    pingCorr = pingCorr((CFG.UseFittedRate and rate) or CFG.RateFlat),

    rateFitted = rate, rateUsed = (CFG.UseFittedRate and rate) or CFG.RateFlat,

    tickPeriod = tickPeriod,
    tickStep = rate and (rate*tickPeriod) or nil,

    srvMeter = phaseAtFire
               and (phaseAtFire + ((CFG.UseFittedRate and rate) or CFG.RateFlat)
                                  * CFG.PingCoef * dataPing())
               or nil,
    samples = nSamples, firstRead = firstR,
    firstReadAt = firstAt and math.floor((firstAt-t0)*1e4)/1e4 or nil,

    shotSpeed = ss, greenVal = HUB.greenVal, meterType = HUB.meterType,
    greenWidth = HUB.greenVal and (HUB.greenVal - CFG.GreenFloor) or nil,
    perfectPossible = (HUB.greenVal ~= nil) and (HUB.greenVal >= CFG.GreenMinOK) or nil,
    input = startArgs and startArgs.Input or nil,

    hoopDist = (hp and og) and math.floor(((hp-og)*FLAT).Magnitude*10)/10 or nil,
    stamina = sAttr(chr(), "Stamina"), action = sAttr(chr(), "Action"),
    -- ТЕЛЕМЕТРИЯ ДАНКА. По ней в следующем дампе будет видно, есть ли у данка
    -- метр вообще и куда мы попадаем: dunkLag это DunkJumpTime - ShotStartTime
    -- (в разобранном дампе он вышел 0.418 с).
    gatherType = sAttr(chr(), "GatherType"),
    baseAnim   = sAttr(chr(), "BaseAnimation"),
    isRim      = PBX.SHOT_RIM[sAttr(chr(), "Action")] == true,
    dunkLag    = (function()
      local dj, st = sAttr(chr(), "DunkJumpTime"), sAttr(chr(), "ShotStartTime")
      if type(dj) == "number" and type(st) == "number" then
        return math.floor((dj - st) * 1e4) / 1e4
      end
      return nil
    end)(),

    attrs = (function()
      local c, out = chr(), {}
      for _, k in ipairs({"Overall","Height","Weight","Takeover","TakeoverFill",
                          "MaxStamina","WalkSpeed","Grade","BuildName","MeterIndex"}) do
        out[k] = sAttr(c, k)
      end
      return out
    end)(),
    spoof = HUB.spoofInfo,
    trace = meterTrace,
  }
  -- ЖУРНАЛ БРОСКОВ БЫЛ БЕЗ ПОТОЛКА.
  -- В каждой записи ~30 полей плюс meterTrace до 40 таблиц, то есть примерно
  -- полсотни таблиц на бросок. За долгую сессию это десятки тысяч живых
  -- объектов, которые никто не собирает. Соседний HUB.jumpLog давно урезан до
  -- десяти — здесь такого не было. Статистика считается по среднему, и
  -- последних трёхсот бросков для неё более чем достаточно.
  HUB.shotsTotal = (HUB.shotsTotal or 0) + 1
  HUB.shots[#HUB.shots+1] = rec
  if #HUB.shots > 300 then table.remove(HUB.shots, 1) end
  HUB.lastShot = rec
end

local A3 = { src = nil }
-- ЗАМЕР РАЗМЕТКИ УБРАН ЦЕЛИКОМ.
-- Поиск зоны, проверка точки в системе координат детали и половинное деление
-- работали технически верно, но давали не ту величину: на трёх площадках
-- 38.7, 48.0 и 38.9, и ни разу не совпало с реальной дугой. Размеченная зона
-- шире линии, и подгонять её коэффициентом — гадание. Линию задаёт игрок.
function A3.arcInfo(hoop, pos)
  if not (hoop and pos) then return nil end
  local flat = (pos - hoop) * FLAT
  local mine = flat.Magnitude
  if mine < 0.1 then return false, 0, mine end

  -- ЛИНИЮ БЕРЁМ С САМОЙ ПЛОЩАДКИ, ЕСЛИ ОНА ЧИТАЕТСЯ.
  -- В прошлой версии замер был только для показа в дампе, и это оказалось
  -- ошибкой: в парке разметка намерена на 38.7 студа, а сравнивали с 23.5 из
  -- настройки. Всё, что дальше 24.5, объявлялось «уже тройка», и Smart 3PT
  -- молча ничего не делал начиная примерно с 25 студов — ровно то, что видно
  -- снаружи. Это не автоподстройка: мы читаем ГЕОМЕТРИЮ площадки, как читали
  -- бы конфиг, и результат виден в дампе. Настройка остаётся запасной и может
  -- быть выбрана принудительно.
  -- ЛИНИЯ БЕРЁТСЯ ТОЛЬКО ИЗ НАСТРОЙКИ.
  -- Замер по разметке снят: на трёх площадках он дал 38.7, 48.0 и 38.9, и ни
  -- разу не совпал с тем, где линия на самом деле. Зона размечена шире дуги,
  -- и лечить это подгонкой смысла нет. Число задаёт игрок, оно предсказуемо.
  local edge = CFG.S3.LineDist
  A3.src = ("line distance %.1f"):format(edge)

  return not (mine < edge + 0.95), edge, mine
end

local function sendShot(payload)
  HUB.bypass = true
  pcall(Mt.FireServer, R.Shoot, payload)
  HUB.bypass = false

  HUB.shotSentGen = HUB.gen
end

function PBX.antiDir(hp, dir, want, realPos)
  HUB.antiShot = nil
  if not (CFG.AntiDef.Enabled and CFG.AntiDef.PreShot) then return dir, false end

  local m = CFG.AntiDef.Mode
  if m ~= "Teleport" and m ~= "Permanent" then return dir, false end

  local foes, nf = foeSnap()
  if nf == 0 then HUB.antiShot = "no enemies"; return dir, false end

  local here = hp + dir*want
  local function nearestFrom(pt)
    local bd
    for i = 1, nf do
      local f = foes[i]
      local w = (CFG.AntiDef.Stance and f.g) and CFG.AntiDef.StanceWeight or 1
      local d = ((f.p - pt) * FLAT).Magnitude / w
      if not bd or d < bd then bd = d end
    end
    return bd or 1e9
  end
  -- ОДИН ПОРОГ НА ОБА РЕЖИМА: React решает «меня накрывают», StopAt — «хватит».
  -- Раньше телепорт брал Keep и Enough, а Legit — свои числа, и одна и та же
  -- мысль была записана двумя парами настроек с разными именами. Keep теперь
  -- принадлежит только постоянному уводу в хуке движения, и ничему больше.
  local fd = nearestFrom(here)
  if fd > CFG.AntiDef.React then
    HUB.antiShot = ("nobody covering at registration (%.1f stds)"):format(fd)
    return dir, false
  end
  local best, bestD = dir, fd

  if bestD >= CFG.AntiDef.StopAt then
    HUB.antiShot = ("already %.1f stds clear"):format(bestD); return dir, false
  end
  local step, maxS = math.rad(CFG.AntiDef.SwingStep), math.rad(CFG.AntiDef.MaxSwing)
  local a = step
  while a <= maxS + 1e-6 do
    for _, sgn in ipairs({ 1, -1 }) do
      local co, si = math.cos(a*sgn), math.sin(a*sgn)

      local nd = Vector3.new(dir.X*co - dir.Z*si, 0, dir.X*si + dir.Z*co)
      local np = hp + nd*want

      if ((np - here) * FLAT).Magnitude <= CFG.AntiDef.MaxShift then
        local d = nearestFrom(np)
        if d > bestD then best, bestD = nd, d end
      end
    end

    if bestD >= CFG.AntiDef.StopAt then break end
    a = a + step
  end
  local moved = (best ~= dir)
  HUB.antiShot = ("swing away: %.1f -> %.1f stds from nearest (shift <= %.0f)")
    :format(fd, bestD, CFG.AntiDef.MaxShift)
  return best, moved
end

local function spoofShot(g, startArgs)
  -- СБРАСЫВАЕМ ДИАГНОСТИКУ ПРОШЛОГО БРОСКА.
  -- HUB.spoofInfo — одна общая таблица, и заполнялась она ТОЛЬКО когда
  -- подмена реально случилась. Каждая запись броска копирует её как есть,
  -- поэтому обычный бросок с 16 студов уносил в журнал realDist = 32.3 и
  -- distSpoof = true от давнего дальнего броска. Снаружи это читается как
  -- «спуф срабатывает в радиусе кольца», хотя подмены не было вовсе.
  HUB.spoofInfo, HUB.smart3Info, HUB.spoofKept, HUB.s3Why = nil, nil, nil, nil
  local pc, me = proxyPart(), selfPos()
  local hp = me and nearestHoop(me)

  -- ОТШАГ ИДЁТ ПАРАЛЛЕЛЬНО БРОСКУ, А НЕ ПЕРЕД НИМ.
  -- Синхронный вызов заставлял бросок ждать весь отшаг. Смысла в такой
  -- очерёдности нет: контест сервер считает на РЕГИСТРАЦИИ броска, значит
  -- отойти надо к этому моменту, а не до отправки.
  if PBX.legitStep then task.spawn(PBX.legitStep, g, hp) end

  if HUB.gen ~= g then
    if HUB.pendingGen == g then PBX.pendClear() end
    return
  end

  me = selfPos()

  local function plain()
    if HUB.gen ~= g then
      if HUB.pendingGen == g then PBX.pendClear() end
      return
    end
    sendShot(startArgs)
    if CFG.Enabled then task.spawn(scheduleRelease, g, os.clock(), startArgs) end
  end
  if not (pc and hp and me) then return plain() end
  local realD = ((me-hp)*FLAT).Magnitude

  -- Только режимы, которые ПОДМЕНЯЮТ позицию на регистрации. Legit и BackTP
  -- двигают по-настоящему и живут в legitStep, спуфу тут делать нечего.
  local wantAnti = CFG.AntiDef.Enabled and CFG.AntiDef.PreShot
                   and (CFG.AntiDef.Mode == "Teleport"
                        or CFG.AntiDef.Mode == "Permanent")

  local ok, realCF = pcall(RDR.CFrame, pc)
  if not ok then return plain() end
  if not physAllowed() then return plain() end

  local flat = (realCF.Position - hp) * FLAT
  local dir  = (flat.Magnitude > 0.1) and flat.Unit or Vector3.new(0,0,1)

  -- ДВЕ НЕЗАВИСИМЫЕ ПОДМЕНЫ, ПОРЯДОК ВАЖЕН.
  -- Smart 3PT спрашивают ПЕРВЫМ, потому что он про ОЧКИ: превратить двойку в
  -- тройку ценнее, чем чуть расширить окно грина. Если он не применим (мы уже
  -- за дугой или до линии слишком далеко), слово переходит спуфу дистанции.
  -- Каждая работает и в одиночку: раньше Smart 3PT жил внутри спуфа и при
  -- выключенном спуфе не делал ничего.
  local want, useFake, why3 = realD, false, nil
  local isThree, edge, mine = nil, nil, nil
  if CFG.S3.Enabled or (CFG.Spoof.Enabled and CFG.Spoof.KeepThree) then
    isThree, edge, mine = A3.arcInfo(hp, realCF.Position)
  end

  if CFG.S3.Enabled then
    -- ПОЧЕМУ ЗДЕСЬ ПОЯВИЛСЯ РАЗБОР ПРИЧИН.
    -- Раньше при неудаче ветка молча ничего не делала, и снаружи Smart 3PT
    -- выглядел как «не работает вообще» без единой подсказки. Теперь каждый
    -- отказ называет себя и уходит в дамп.
    if edge == nil then
      HUB.s3Why = "three point line not found on the court"
    elseif isThree then
      HUB.s3Why = ("already a 3 (%.1f past the %.1f line)"):format(mine or realD, edge)
    else
      local need = edge + 0.95 + CFG.S3.Extra
      local gap  = need - (mine or realD)
      if gap <= 0 then
        HUB.s3Why = "nothing to gain, already past the line"
      elseif gap > CFG.S3.Window then
        HUB.s3Why = ("too far from the line: %.1f stds short, reach is %.1f")
          :format(gap, CFG.S3.Window)
      else
        want, useFake = need, true
        why3 = ("2->3: %.1f -> %.1f (line %.1f, %s)")
          :format(mine or realD, need, edge, tostring(A3.src))
        HUB.s3Why = why3
      end
    end
  end

  if not why3 and CFG.Spoof.Enabled and realD >= CFG.Spoof.MinRealDist then
    want, useFake = CFG.Spoof.FakeDist, true
    -- ТРОЙКУ НЕ ОТДАЁМ ЗА ОКНО ГРИНА.
    -- Подмена ведёт к кольцу, и с 30 студов FakeDist = 12 ставит нас глубоко
    -- внутрь дуги: сервер засчитает двойку вместо тройки. Если мы уже за
    -- линией — не заходим внутрь неё, только подтягиваемся к ней.
    if CFG.Spoof.KeepThree and isThree and edge then
      local floorD = edge + 0.95 + 0.25
      if want < floorD then
        want = floorD
        HUB.spoofKept = ("kept the 3: %.1f instead of %.1f"):format(want, CFG.Spoof.FakeDist)
      end
    end
  end

  if not useFake and not wantAnti then return plain() end

  local moved = false
  if wantAnti then dir, moved = PBX.antiDir(hp, dir, want, realCF.Position) end

  if not useFake and not moved then return plain() end
  local fake = hp + dir*want + Vector3.new(0, realCF.Position.Y-hp.Y, 0)

  local fakeCF = lookAtCF(fake, hp, pc)
  if not fakeCF then return plain() end
  local regAt = HUB.regSeq
  HUB.spoofInfo = { realDist = realD, fakeDist = want, smart3 = why3,
                    distSpoof = useFake, dodged = moved, anti = HUB.antiShot }
  if why3 then HUB.smart3Info = why3 end
  if not (HUB.antiStepUntil and os.clock() < HUB.antiStepUntil) then tpProxy(pc, fakeCF) end
  local t1 = os.clock()

  task.wait(CFG.Spoof.PreTime)
  if HUB.gen~=g then
    tpProxy(pc, realCF)
    if HUB.pendingGen == g then PBX.pendClear() end
    return
  end

  sendShot(startArgs)
  if CFG.Enabled then task.spawn(scheduleRelease, g, os.clock(), startArgs) end

  if CFG.Spoof.HoldUntilRegister then
    local t2 = os.clock()
    while HUB.running and HUB.regSeq <= regAt and os.clock()-t2 < CFG.Spoof.HoldMax do
      if not (HUB.antiStepUntil and os.clock() < HUB.antiStepUntil) then tpProxy(pc, fakeCF) end
      RunService.Heartbeat:Wait()
    end
  end

  local holdFor = (why3 and CFG.S3.Hold) and CFG.S3.HoldMax or 0

  if wantAnti and moved and CFG.AntiDef.Mode == "Permanent" then
    HUB.antiShot = (HUB.antiShot or "") .. " [permanent]"
    return
  end

  if wantAnti and moved and holdFor <= 0 then
    for _ = 1, CFG.AntiDef.BoostFrames do
      if not (HUB.antiStepUntil and os.clock() < HUB.antiStepUntil) then tpProxy(pc, fakeCF) end
      RunService.Heartbeat:Wait()
    end
    tpProxy(pc, realCF)
    if HUB.spoofInfo then HUB.spoofInfo.antiFrames = CFG.AntiDef.BoostFrames end
    return
  end
  if holdFor > 0 then
    local fseq = HUB.feedSeq or 0
    local t3 = os.clock()

    local sawFlight = false
    while HUB.running and HUB.gen == g
          and (HUB.feedSeq or 0) == fseq
          and os.clock() - t3 < holdFor do

      if HUB.ballInFlight then
        sawFlight = true
      elseif sawFlight then
        break
      end
      if not (HUB.antiStepUntil and os.clock() < HUB.antiStepUntil) then tpProxy(pc, fakeCF) end
      RunService.Heartbeat:Wait()
    end
    if HUB.spoofInfo then
      HUB.spoofInfo.heldMs = math.floor((os.clock()-t3)*10000)/10
      HUB.spoofInfo.resolved = ((HUB.feedSeq or 0) ~= fseq)
      HUB.spoofInfo.heldFor = holdFor
    end
  end
  tpProxy(pc, realCF)
  if HUB.spoofInfo then
    HUB.spoofInfo.exposureMs = math.floor((os.clock()-t1)*10000)/10
  end
end

local oldNamecall
local hookFn = newcclosure(function(self, ...)

  if self ~= R.Shoot or HUB.bypass
     or not (CFG.Enabled or CFG.Spoof.Enabled or CFG.S3.Enabled or CFG.Zero.Enabled
             or (CFG.AntiDef.Enabled and CFG.AntiDef.PreShot)) then
    return oldNamecall(self, ...)
  end
  if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
  local a = (...)
  if type(a) ~= "table" then return oldNamecall(self, ...) end

  -- Раньше здесь стоял hasBall, и данк проходил мимо: мяч уже в воздухе.
  local haveBall = CFG.TimeDunks and PBX.hasBallLike(chr()) or hasBall(chr())
  if not haveBall then return oldNamecall(self, ...) end

  if a.Shoot == true then
    local t0 = os.clock()
    HUB.shotPressAt = t0
    HUB.gen += 1
    local g = HUB.gen
    PBX.pendHold(g)
    local copy = {}
    for k,v in pairs(a) do copy[k]=v end

    if CFG.Zero.Enabled then
      if CFG.Zero.KillSprint then copy.Sprint = false end

      if CFG.Zero.FromStart then

        zeroHold(CFG.Enabled and (CFG.Zero.Tail + 0.12)
                              or (CFG.MaxWait + CFG.Zero.Tail))
      end
    end

    if not CFG.Enabled then PBX.pendClear() end

    if CFG.Spoof.Enabled or CFG.S3.Enabled
       or (CFG.AntiDef.Enabled and CFG.AntiDef.PreShot) then
      task.spawn(spoofShot, g, copy)
      return
    end
    if CFG.Enabled then task.spawn(scheduleRelease, g, t0, copy) end

    if CFG.Zero.Enabled and CFG.Zero.KillSprint then
      sendShot(copy)
      return
    end
    HUB.shotSentGen = g
    return oldNamecall(self, ...)
  elseif a.Shoot == false then
    HUB.shotPressAt = nil

    if PBX.pendActive() and HUB.shotSentGen ~= HUB.gen then
      HUB.gen += 1
      PBX.pendClear()
      zeroRelease()
      HUB.shotCancelled = (HUB.shotCancelled or 0) + 1
      HUB.lastCancelAt = os.clock()
      return oldNamecall(self, ...)
    end
    if PBX.pendActive() then return end

    if CFG.Zero.Enabled and not CFG.Enabled then
      task.delay(CFG.Zero.Tail + 0.02, zeroRelease)
    end
    return oldNamecall(self, ...)
  end
  return oldNamecall(self, ...)
end)

if CFG.Stealth.HideStack and setstackhidden then
  pcall(setstackhidden, hookFn, true)
end
oldNamecall = hookmetamethod(game, "__namecall", hookFn)

local TIMING = {"Very Early","Early","Slightly Early","Good","Perfect",
                "Slightly Late","Late","Very Late"}
if R.Feed then
  track(R.Feed.OnClientEvent:Connect(function(...)
    local a = {...}
    if not isMine(a[1]) then HUB.foreign.feed += 1; return end
    local idx = tonumber(a[3])
    local nm = idx and TIMING[idx] or tostring(a[3])
    HUB.stats[nm] = (HUB.stats[nm] or 0) + 1
    if HUB.lastShot and not HUB.lastShot.verdict then
      HUB.lastShot.verdict = nm; HUB.lastShot.contest = a[2]
      HUB.feedSeq = (HUB.feedSeq or 0) + 1
    end
    HUB.streak = (idx==5) and ((HUB.streak or 0)+1) or 0
    if CFG.Debug.Verdict then
      local ls, tot = HUB.lastShot, 0
      for _,v in pairs(HUB.stats) do tot+=v end
      rep(("[PB] %s | Perfect %d/%d | phase=%.3f tgt=%.3f ping=%.0fms(%s) green=%.4f(w=%.3f) by=%s")
        :format(nm, HUB.stats["Perfect"] or 0, tot,
                (ls and ls.phase) or -1, (ls and ls.target) or 0,
                ((ls and ls.ping) or 0)*1000, (ls and ls.pingSource) or "?",
                (ls and ls.greenVal) or 0,
                (ls and ls.greenWidth) or 0, (ls and ls.firedBy) or "?"))
    end
  end))
end

local ballCache, ballCacheAt, scanAt = {}, 0, 0
local function findBalls()
  local now = os.clock()
  if now - ballCacheAt < CFG.Traj.TagEvery then return ballCache end
  ballCacheAt = now
  local ok, tagged = pcall(function() return CollSvc:GetTagged("Basketballs") end)
  if ok and tagged and #tagged > 0 then ballCache = tagged; return ballCache end
  if now - scanAt < CFG.Traj.ScanEvery then return ballCache end
  scanAt = now
  local out = {}
  local ok2, kids = pcall(Mt.GetDescendants, Workspace)
  if ok2 then
    for _, o in ipairs(kids) do
      local n = o.Name
      if type(n)=="string" and (n:lower():find("basketball") or n == "Ball") then
        local okc, cls = pcall(RDR.ClassName, o)
        if okc and (cls == "Part" or cls == "MeshPart" or cls == "UnionOperation") then
          out[#out+1] = o
        end
      end
    end
  end
  ballCache = out
  return ballCache
end

local BS = {}

local BALL = { part=nil, pos=nil, vel=nil, speed=0, state="none",
               holder=nil, shooter=nil, tFlight=0, tSeen=0,
               velSrc="fit", stale=0, fitN=0 }

PBX.OWN_BALL = { PickingUp = true, CatchingPass = true, AwaitingPass = true,
                 CatchingLob = true, PassTransition = true, Dribbling = true,
                 Passing = true, Shooting = true, Gathering = true,
                 Dunking = true, ContactLayup = true, ClutchLayup = true,
                 Inbounding = true, TripleThreat = true }
function PBX.ballIsOurs()
  local c = chr(); if not c then return false end
  if hasBall(c) then return true end
  if PBX.OWN_BALL[sAttr(c, "Action")] then return true end
  if BALL.holder ~= nil and BALL.holder == c then return true end
  return false
end

local function holderOf(bpos)
  for _, c in ipairs(charsList()) do
    if hasBall(c) then
      local p = posOf(sChild(c, "HumanoidRootPart"))
      if p and (p - bpos).Magnitude <= CFG.Traj.HoldDist then return c end
    end
  end
  return nil
end
local updateBall = LPH_NO_VIRTUALIZE(function()

  if not (CFG.Traj.Enabled or CFG.Grab.Enabled or CFG.Defense.Enabled) then
    if BALL.state ~= "idle" then BALL.state, BALL.speed = "idle", 0 end
    return
  end
  local now = os.clock()
  local me = selfPos()
  local best, bestScore

  local balls = findBalls()
  local mine = nil
  if PK.ref then
    local bv = sChild(sChild(PK.ref, "Attributes"), "Basketball")
    if bv then
      local okv, v = pcall(RDR.Value, bv)
      if okv and v then
        for _, b in ipairs(balls) do if b == v then mine = v; break end end
      end
    end
  end
  HUB.matchBall = mine and true or false

  local hoopsMine = (not mine) and hoopList() or nil
  for _, b in ipairs(balls) do
   local okCourt = true
   if mine then
     okCourt = (b == mine)
   elseif hoopsMine and #hoopsMine > 0 then
     okCourt = false
     local bp = posOf(b)
     if bp then
       for _, hp in ipairs(hoopsMine) do
         if ((bp - hp) * FLAT).Magnitude <= 150 then okCourt = true; break end
       end
     end
   end
   if okCourt then
    local p = posOf(b)
    if p then
      local st = BS[b]
      if not st then st = { buf = {} }; BS[b] = st end
      local last = st.buf[#st.buf]

      local moved = (not last) or (p - last.p).Magnitude > 1e-3
      if moved then st.lastMove = now end

      if st.lastMove and (now - st.lastMove) > 0.30 then
        st.vel = nil
        if #st.buf > 1 then st.buf = { { t = now, p = p } } end
      end

      if moved and last then
        local dtj = now - last.t
        if dtj > 0 and (p - last.p).Magnitude / dtj > CFG.Traj.MaxSpeed then
          st.buf = { { t = now, p = p } }
          st.vel = nil
          st.jumps = (st.jumps or 0) + 1
          HUB.ballJumps = (HUB.ballJumps or 0) + 1
          moved = false
        end
      end
      if moved and ((not last) or (now - last.t) > 0.004) then
        st.buf[#st.buf+1] = { t = now, p = p }

        while #st.buf > 2 and (now - st.buf[1].t) > CFG.Traj.FitWindow do
          table.remove(st.buf, 1)
        end
        while #st.buf > CFG.Traj.FitSamples do table.remove(st.buf, 1) end
        local n = #st.buf
        if n >= 3 then

          local g = Vector3.new(0, -Workspace.Gravity, 0)
          local t0b = st.buf[1].t
          local sT,sTT = 0,0
          local sQ, sTQ = Vector3.new(), Vector3.new()
          for _, e in ipairs(st.buf) do
            local tt = e.t - t0b
            local q  = e.p - g*(0.5*tt*tt)
            sT += tt; sTT += tt*tt; sQ += q; sTQ += q*tt
          end

          local span = st.buf[n].t - t0b
          local den = n*sTT - sT*sT
          if span > 0.015 and math.abs(den) > 1e-6 then
            local v0 = (sTQ*n - sQ*sT)/den
            local p0f = (sQ*sTT - sTQ*sT)/den

            local res, rs = {}, {}
            for i, e in ipairs(st.buf) do
              local tt = e.t - t0b
              local pr = p0f + v0*tt + g*(0.5*tt*tt)
              local d = (e.p - pr).Magnitude
              res[i] = d; rs[#rs+1] = d
            end
            table.sort(rs)
            local med = rs[math.max(1, math.floor(#rs/2))] or 0
            local lim = math.max(med * 3, 0.75)
            local keep = {}
            for i, e in ipairs(st.buf) do
              if res[i] <= lim then keep[#keep+1] = e end
            end
            if #keep >= 3 and #keep < n then
              local k = #keep
              local kT,kTT = 0,0
              local kQ,kTQ = Vector3.new(), Vector3.new()
              local kt0 = keep[1].t
              for _, e in ipairs(keep) do
                local tt = e.t - kt0
                local q = e.p - g*(0.5*tt*tt)
                kT += tt; kTT += tt*tt; kQ += q; kTQ += q*tt
              end
              local kden = k*kTT - kT*kT
              if (keep[k].t - kt0) > 0.015 and math.abs(kden) > 1e-6 then
                v0 = (kTQ*k - kQ*kT)/kden
                t0b = kt0
                st.dropped = n - k
                HUB.fitDropped = (HUB.fitDropped or 0) + (n - k)
              end
            else
              st.dropped = 0
            end
            local vNow = v0 + g*(now - t0b)

            if st.vel and st.velT then st.vel = st.vel + g*(now - st.velT) end
            st.velT = now
            if st.vel and (vNow - st.vel).Magnitude < CFG.Traj.VelJump then
              st.vel = st.vel:Lerp(vNow, CFG.Traj.VelSmooth)
            else
              st.vel = vNow
            end
          end
        elseif n == 2 then
          local dt = st.buf[2].t - st.buf[1].t
          if dt > 0.004 then
            st.vel = (st.buf[2].p - st.buf[1].p)/dt
            st.velT = now
          end
        end

        if st.vel and (st.vel ~= st.vel or st.vel.Magnitude > CFG.Traj.MaxSpeed) then
          st.vel = nil
          st.buf = { { t = now, p = p } }
        end
      end

      st.velSrc = "fit"
      st.fitN = #st.buf

      local sp = st.vel and st.vel.Magnitude or 0
      if sp >= CFG.Traj.MinSpeed then
        local d = me and (p - me).Magnitude or 999
        local score = 1000 - d
        if not bestScore or score > bestScore then

          local stale = now - (st.lastMove or now)
          best, bestScore = { part=b, pos=p, vel=st.vel, speed=sp,
                              src=st.velSrc,
                              stale=stale, fitN=st.fitN or 0 }, score
        end
      end
    end
   end
  end

  if best then
    if BALL.state ~= "flight" then
      BALL.tFlight = now
      BALL.release = best.pos
    end
    BALL.part, BALL.pos, BALL.vel, BALL.speed = best.part, best.pos, best.vel, best.speed
    BALL.velSrc, BALL.stale = best.src, best.stale
    BALL.fitN = best.fitN
    BALL.state = "flight"
    BALL.tSeen = now
    BALL.holder = holderOf(best.pos)
    if BALL.holder then BALL.shooter = BALL.holder end

    if BALL.release and BALL.vel and BALL.shooter
       and BALL.arcLearned ~= BALL.tFlight and (BALL.fitN or 0) >= 8 then
      BALL.arcLearned = BALL.tFlight
      local tgt = goalPosOf(BALL.shooter)
      if tgt then
        local vh = (BALL.vel * FLAT).Magnitude
        local dh = ((tgt - BALL.release) * FLAT).Magnitude
        if vh > 5 and dh > 3 then
          local T = dh / vh
          local ae = T - (tgt - BALL.release).Magnitude / 85
          if ae > 0.05 and ae < 1.2 then

            local d3 = (tgt - BALL.release).Magnitude
            local k = (d3 < 15) and "near" or ((d3 < 30) and "mid" or "far")
            HUB.arcEffB = HUB.arcEffB or {}
            local b = HUB.arcEffB[k]
            HUB.arcEffB[k] = b and (b*0.8 + ae*0.2) or ae
            HUB.arcEff = HUB.arcEff and (HUB.arcEff*0.8 + ae*0.2) or ae
            HUB.arcEffN = (HUB.arcEffN or 0) + 1
          end
        end
      end
    end

  elseif BALL.state == "flight" and (now - (BALL.tSeen or 0)) < CFG.Traj.FlightHold then

    BALL.stale = (BALL.stale or 0) + (now - (BALL.lastTick or now))
  else
    BALL.state, BALL.holder, BALL.speed = "idle", nil, 0
  end
  BALL.lastTick = now

  HUB.ballInFlight = (BALL.state == "flight")
end)
track(RunService.Heartbeat:Connect(updateBall))

local function trajWhy()
  if BALL.state ~= "flight" then
    return false, ("no ball in flight (state %s)"):format(BALL.state)
  end
  if not BALL.vel then return false, "no velocity" end
  if hasBall(chr()) then return false, "we hold the ball" end

  if CFG.Traj.SkipTeammates and BALL.shooter and isMate(BALL.shooter) then
    return false, "teammate shot it"
  end
  return true, "ok"
end
local function trajVisible() local ok = trajWhy() return ok end

task.spawn(function()
  while HUB.running do
    task.wait(2)
    if CFG.Traj.Enabled and CFG.Traj.Diag then
      local ok, why = trajWhy()
      if not ok then
        HUB.trajWhy = why
        rep(("[PB] trajectory: %s | balls=%d | speed=%.1f (min %.0f)")
          :format(why, #findBalls(), BALL.speed or 0, CFG.Traj.MinSpeed))
      elseif HUB.lastHoopDist then
        rep(("[PB] arc: closest approach to hoop %.2f stds (score radius %.2f) hoops=%d")
          :format(HUB.lastHoopDist, CFG.Traj.ScoreRad, #hoopList()))
      end
    end
  end
end)

local arcRay, arcRayProxy, arcRayBall = nil, nil, nil
local function arcRayParams(ball)
  local pc = proxyPart()
  if arcRay and arcRayProxy == pc and arcRayBall == ball then return arcRay end
  arcRay = arcRay or RaycastParams.new()
  arcRay.FilterType = Enum.RaycastFilterType.Exclude
  local list = {}
  local ch = sChild(Workspace, "Characters");  if ch then list[#list+1] = ch end
  local bb = sChild(Workspace, "Basketballs"); if bb then list[#list+1] = bb end
  if pc then list[#list+1] = pc end
  if ball then list[#list+1] = ball end
  arcRay.FilterDescendantsInstances = list
  arcRay.IgnoreWater = true
  pcall(function() arcRay.RespectCanCollide = true end)
  arcRayProxy, arcRayBall = pc, ball
  return arcRay
end

function PBX.hoopParts()
  local now = os.clock()
  if PBX.hpList and now - (PBX.hpAt or 0) < 5 then return PBX.hpList end
  PBX.hpAt = now
  local out = {}
  local hoops = sChild(Workspace, "Hoops")
  if hoops then
    local ok, kids = pcall(Mt.GetDescendants, hoops)
    if ok then
      for _, d in ipairs(kids) do
        if d:IsA("BasePart") and d.Name ~= "Goal" then
          local okp, par = pcall(RDR.Parent, d)
          if okp and par and par.Name ~= "Net" and par.Name ~= "Nets" then
            out[#out+1] = d
          end
        end
      end
    end
  end
  PBX.hpList = out
  return out
end

function PBX.hoopRay(cp, seg)
  local list = PBX.hoopParts()
  if #list == 0 then return nil end
  PBX.hpRP = PBX.hpRP or RaycastParams.new()
  PBX.hpRP.FilterType = Enum.RaycastFilterType.Include
  PBX.hpRP.FilterDescendantsInstances = list
  pcall(function() PBX.hpRP.RespectCanCollide = false end)
  local ok, hit = pcall(function() return Workspace:Raycast(cp, seg, PBX.hpRP) end)
  return ok and hit or nil
end

-- Per-step predicate inside the native PBX.march loop (called up to
-- Samples/PhysSamples times per arc per frame). Kept native so each march step
-- does not bounce back into the VM.
local segNeedsRay = LPH_NO_VIRTUALIZE(function(a, b, floorY)
  if floorY and (a.Y <= floorY + 4 or b.Y <= floorY + 4) then return true end
  local r = CFG.Traj.RayNear
  for _, hp in ipairs(hoopList()) do
    if (a - hp).Magnitude <= r or (b - hp).Magnitude <= r then return true end
  end
  return false
end)

-- HEAVY: the trajectory physics integrator. n = 48..64 steps/frame with
-- raycasts + bounce reflection + vector math, called EVERY frame by the
-- arc-predict Heartbeat, the RenderStepped draw loop, and the grab/defense
-- ticks. Wrapping the callbacks alone did NOT fix the post-Luraph lag because
-- each call re-entered the VM here; wrapping this definition keeps the whole
-- integration loop native (its callers were already wrapped).
PBX.march = LPH_NO_VIRTUALIZE(function(p0, v0, dur, n, ball)
  local g = Vector3.new(0, -Workspace.Gravity, 0)
  local arc, step = {}, dur / n
  local floorY = (charComp and rawget(charComp, "lastValidHeight")) or nil
  if type(floorY) ~= "number" then floorY = nil end
  local cp, cv, t = p0, v0, 0
  arc.p0, arc.v0 = p0, v0
  arc[1] = { t = 0, p = cp }
  local bounces, rays = 0, 0
  for _ = 1, n do
    local np = cp + cv*step + g*(0.5*step*step)
    if bounces < CFG.Traj.Bounces and rays < CFG.Traj.RayBudget then
      local seg = np - cp
      if seg.Magnitude > 1e-4 and segNeedsRay(cp, np, floorY) then
        rays += 1

        local res = PBX.hoopRay(cp, seg)
        local ok, world = pcall(function()
          return Workspace:Raycast(cp, seg, arcRayParams(ball))
        end)
        if ok and world then
          if not res or (world.Position - cp).Magnitude < (res.Position - cp).Magnitude then
            res = world
          end
        end
        if res then

          local dt = step * math.clamp((res.Position - cp).Magnitude / seg.Magnitude, 0, 1)
          t += dt
          bounces += 1
          arc[#arc+1] = { t = t, p = res.Position, hit = true, bounce = bounces }
          local nrm = res.Normal
          local vAt = cv + g*dt
          cv = (vAt - nrm * (2 * vAt:Dot(nrm))) * CFG.Traj.BounceKeep
          cp = res.Position + nrm * 0.15
          continue
        end
      end
    end
    cv = cv + g*step
    cp = np
    t += step
    arc[#arc+1] = { t = t, p = cp, v = cv }
  end
  arc.bounces = bounces
  return arc
end)

-- Thin lag-compensation wrapper over PBX.march. Kept native too so the whole
-- predict→march call path stays out of the VM on every frame.
local predictArc = LPH_NO_VIRTUALIZE(function(pos, vel, velSrc, stale, ball, mapCheck)
  local g = Vector3.new(0, -Workspace.Gravity, 0)
  local lag = CFG.Traj.RenderLag + math.min(stale or 0, 0.25)
  local p0 = (lag > 0) and (pos + vel*lag + g*(0.5*lag*lag)) or pos
  local v0 = (lag > 0) and (vel + g*lag) or vel

  local n   = mapCheck and CFG.Traj.Samples or CFG.Traj.PhysSamples
  local dur = mapCheck and CFG.Traj.Duration or CFG.Traj.PhysDuration
  return PBX.march(p0, v0, dur, n, ball)
end)

local function ballTrueNow(pos, vel, stale)
  local p = pos or BALL.pos
  local v = vel or BALL.vel
  if not (p and v) then return p, v end
  local g = Vector3.new(0, -Workspace.Gravity, 0)
  local lag = CFG.Traj.RenderLag + math.min(stale or BALL.stale or 0, 0.25)
  return p + v*lag + g*(0.5*lag*lag), v + g*lag
end

local lines, marks = {}, {}
local function mkLine(i)
  if lines[i] == nil then
    local ok,d = pcall(function()
      local l = Drawing.new("Line")
      l.Thickness = CFG.Traj.Thick; l.Transparency = 1
      l.ZIndex = CFG.Traj.ZIndex;   l.Visible = false
      return l
    end)
    lines[i] = ok and d or false
  end
  return lines[i] or nil
end
local function mkMark(i)
  if marks[i] == nil then
    local ok,d = pcall(function()
      local c = Drawing.new("Circle")
      c.Thickness = 2; c.NumSides = 18; c.Radius = 8
      c.Filled = false; c.Transparency = 1
      c.ZIndex = CFG.Traj.ZIndex + 1; c.Visible = false
      return c
    end)
    marks[i] = ok and d or false
  end
  return marks[i] or nil
end
local function hideAll()
  for _,l in pairs(lines) do if l then pcall(function() l.Visible=false end) end end
  for _,m in pairs(marks) do if m then pcall(function() m.Visible=false end) end end
end

HUB.arc = nil
track(RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
  if not HUB.running then HUB.arc = nil; return end
  if BALL.state ~= "flight" or not BALL.vel then HUB.arc = nil; return end
  local arc = predictArc(BALL.pos, BALL.vel, BALL.velSrc, BALL.stale, BALL.part, false)

  local hits, hi, hd, gp = false, nil, nil, nil
  local hoops = hoopList()
  if #hoops == 0 then
    local d1 = defendGoalPos(BALL.shooter)
    if d1 then hoops = { d1 } end
  end

  for _, hp in ipairs(hoops) do
    for i, sp in ipairs(arc) do
      local dd = (sp.p - hp).Magnitude
      if not hd or dd < hd then hi, hd, gp = i, dd, hp end
    end
  end

  local preHit = #arc
  for i, sp in ipairs(arc) do if sp.hit then preHit = i - 1; break end end
  local sd
  for _, hp in ipairs(hoops) do
    for i = 2, preHit do
      local sp = arc[i]
      if sp.p.Y < arc[i-1].p.Y and sp.p.Y >= hp.Y - CFG.Traj.ScoreRad then
        local dd = ((sp.p - hp) * FLAT).Magnitude
        if not sd or dd < sd then sd = dd end
      end
    end
  end
  hits = (sd ~= nil and sd <= CFG.Traj.ScoreRad)
  HUB.scoreDist = sd

  if hits ~= HUB.hitsRaw then HUB.hitsSeen = 0 else HUB.hitsSeen = (HUB.hitsSeen or 0) + 1 end
  HUB.hitsRaw = hits
  if (HUB.hitsSeen or 0) >= 1 then HUB.hitsStable = hits end
  hits = (HUB.hitsStable ~= nil) and HUB.hitsStable or hits
  HUB.lastHoopDist = hd
  HUB.arc = { arc = arc, hits = hits, hoopIdx = hi, hoopDist = hd,
              goal = gp, shooter = BALL.shooter, ball = BALL.part,
              fitN = BALL.fitN or 0 }

  HUB.predQ = HUB.predQ or { q = {}, fit = { n=0, sum=0, max=0 },
                             fit8 = { n=0, sum=0, max=0 },
                             shot = { n=0, sum=0, max=0 } }
  HUB.predQ.shot = HUB.predQ.shot or { n=0, sum=0, max=0 }
  local Q = HUB.predQ
  local ck = CFG.Traj.PredCheck

  if ((not Q.lastPush) or (os.clock() - Q.lastPush) > 0.10)
     and (BALL.fitN or 0) >= CFG.Traj.MinFitN then
    Q.lastPush = os.clock()
    local g = Vector3.new(0, -Workspace.Gravity, 0)
    local pFit = BALL.pos + BALL.vel*ck + g*(0.5*ck*ck)

    local gl = groundLevel()
    local free = (BALL.holder == nil)
      and ((not gl) or (BALL.pos.Y - gl) > CFG.Grab.MinAbove)
    Q.q[#Q.q+1] = { at = os.clock() + ck, fit = pFit, ball = BALL.part,
                    tf = BALL.tFlight, fn = BALL.fitN or 0, free = free }
  end
  for i = #Q.q, 1, -1 do
    local e = Q.q[i]
    if os.clock() >= e.at then
      local actual = posOf(e.ball)

      if actual and BALL.state == "flight" and BALL.part == e.ball
         and BALL.tFlight == e.tf and (BALL.stale or 0) < 0.02 then
        local ef = (actual - e.fit).Magnitude
        Q.fit.n += 1; Q.fit.sum += ef
        if ef > Q.fit.max then Q.fit.max = ef end
        if (e.fn or 0) >= 8 then
          Q.fit8.n += 1; Q.fit8.sum += ef
          if ef > Q.fit8.max then Q.fit8.max = ef end

          if e.free and BALL.holder == nil then
            Q.shot.n += 1; Q.shot.sum += ef
            if ef > Q.shot.max then Q.shot.max = ef end
          end
        end
        if e.phys then
          local ep = (actual - e.phys).Magnitude
          Q.phys.n += 1; Q.phys.sum += ep
          if ep > Q.phys.max then Q.phys.max = ep end
        end
      end
      table.remove(Q.q, i)
    end
  end
end)))

local TF = {}
local function tf(reason)
  TF[reason] = (TF[reason] or 0) + 1
end
HUB.trajFunnel = TF

track(RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
  tf("frames")
  if not (CFG.Traj.Enabled and HUB.running) then
    tf(CFG.Traj.Enabled and "script stopped" or "toggle off"); hideAll(); return
  end
  if not HUB.arc then tf("no arc built") end
  do
    local ok, why = trajWhy()
    if not ok then tf(why or "hidden") end
  end
  if not (trajVisible() and HUB.arc) then hideAll(); return end
  tf("drawn")

  local a2 = predictArc(BALL.pos, BALL.vel, BALL.velSrc, BALL.stale, BALL.part,
                        CFG.Traj.MapCheck)
  local arc = (a2 and #a2 > 1) and a2 or HUB.arc.arc
  local hits = HUB.arc.hits

  local hi = nil
  local hg = HUB.arc.goal
  if hg then
    local bd
    for i, sp in ipairs(arc) do
      local d = (sp.p - hg).Magnitude
      if not bd or d < bd then hi, bd = i, d end
    end
  end
  local cam = Workspace.CurrentCamera
  if not cam then hideAll() return end
  local col = hits and CFG.Traj.ColorIn or CFG.Traj.ColorOut
  local used = 0
  for i = 1, #arc-1 do
    local s1, on1 = cam:WorldToViewportPoint(arc[i].p)
    local s2, on2 = cam:WorldToViewportPoint(arc[i+1].p)
    used += 1
    local l = mkLine(used)
    if l then
      if on1 and on2 then
        l.From = Vector2.new(s1.X, s1.Y)
        l.To   = Vector2.new(s2.X, s2.Y)
        l.Color = col; l.Visible = true
      else l.Visible = false end
    end
  end
  for i = used+1, #lines do local l=lines[i]; if l then l.Visible=false end end

  if CFG.Traj.Marks then

    local last = arc[#arc]
    local pts = { arc[1].p, hi and arc[hi].p or nil,
                  (last and last.hit) and last.p or nil }
    local cols = { Color3.fromRGB(255,220,0), col, Color3.fromRGB(255,255,255) }
    local rads = { 7, 11, 5 }
    for i = 1, 3 do
      local m = mkMark(i)
      if m then
        local wp = pts[i]
        if wp then
          local sp2, on = cam:WorldToViewportPoint(wp)
          if on then
            m.Position = Vector2.new(sp2.X, sp2.Y)
            m.Color = cols[i]
            m.Radius = rads[i]
            m.Visible = true
          else m.Visible = false end
        else m.Visible = false end
      end
    end
  end
end)))

function PBX.predSlack(tAhead)
  local q = HUB.predQ and HUB.predQ.shot

  local perCheck = (q and q.n and q.n >= 20 and q.sum / q.n) or 2.0
  local perSec = perCheck / math.max(CFG.Traj.PredCheck, 0.05)
  return math.clamp(perSec * math.clamp(tAhead or 0, 0, 1.6), 0, CFG.Traj.MaxSlack)
end

local function pickInterceptPoint(info, opt)

  local needFit = opt.fitN or CFG.Traj.MinFitN
  if (info.fitN or 0) < needFit then
    return nil, nil, nil, ("fit not converged yet (%d/%d points)")
      :format(info.fitN or 0, needFit)
  end
  if opt.skipOwn and info.shooter then
    if info.shooter == chr() then return nil, nil, nil, "our own shot" end
    if not isEnemy(info.shooter) then return nil, nil, nil, "teammate shot it" end
  end

  local hoops, scope
  if opt.goalCheck then
    local gp = hoopWeDefend()
    if not gp then return nil, nil, nil, "our hoop undetermined" end
    hoops, scope = { gp }, "our hoop"
  else
    hoops, scope = hoopList(), "nearest hoop"
    if #hoops == 0 then return nil, nil, nil, "no hoops found" end
  end

  local bi, bd, gp
  for _, hp in ipairs(hoops) do
    for i, sp in ipairs(info.arc) do
      local d = (sp.p - hp).Magnitude
      if not bd or d < bd then bi, bd, gp = i, d, hp end
    end
  end
  HUB.lastHoopDist = bd

  local tAt   = (bi and info.arc[bi] and info.arc[bi].t) or 0

  local slack = opt.noSlack and 0 or PBX.predSlack(tAt)
  local tol   = (opt.rad or 6) + slack
  HUB.lastHoopTol, HUB.lastHoopT = tol, tAt
  if not bi or (bd or 1e9) > tol then
    return nil, bd, gp,
      ("ball not heading to hoop: closest to %s %.1f > %.1f (base %.1f + pred slack %.1f at %.2fs)")
        :format(scope, bd or -1, tol, opt.rad or 6, slack, tAt)
  end
  return bi, bd, gp, nil
end

local function ourSpeed()
  local ws = sAttr(chr(), "WalkSpeed")
  ws = (type(ws)=="number") and math.min(ws, 14) or 14
  local st = sAttr(chr(), "Stamina")
  if CFG.Grab.Sprint and (type(st)~="number" or st > 20) then ws = ws + 3.35 end
  return ws * CFG.Grab.SpeedPad
end

local TRN = { hooked = {} }
function TRN.installTurnHook()
  if next(TRN.hooked) then return true end
  if not (filtergc and hookfunction) then HUB.turnSrc = "no filtergc/hookfunction"; return false end
  local ok, list = pcall(filtergc, "function", { Name = "UpdateTurn" }, false)
  if not (ok and type(list) == "table") then HUB.turnSrc = "UpdateTurn not found"; return false end
  local n = 0
  for _, fn in ipairs(list) do
    if type(fn) == "function" and not TRN.hooked[fn] then
      local orig
      local okh = pcall(function()
        orig = hookfunction(fn, function(self, dt)
          local r = orig(self, dt)
          local yaw = HUB.wantYaw
          if yaw then

            local okw = pcall(function()
              local mv = self.Movement
              local mo, root = mv.MovementOrientation, mv.Root
              if mo and root then
                mo.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
                HUB.turnApplied = os.clock()
              end
            end)
            HUB.turnOK = okw
          end
          return r
        end)
      end)
      if okh and orig then TRN.hooked[fn] = orig; n += 1 end
    end
  end
  if n == 0 then HUB.turnSrc = "hookfunction failed"; return false end
  HUB.turnSrc = ("UpdateTurn x%d"):format(n)
  return true
end
function TRN.removeTurnHook()
  HUB.wantYaw = nil
  if restorefunction then
    for fn in pairs(TRN.hooked) do pcall(restorefunction, fn) end
  end
  table.clear(TRN.hooked)
end
track({ Disconnect = TRN.removeTurnHook })

local function faceBall(ballPos, dt, rate, smooth)
  if not TRN.installTurnHook() then return end
  local p = selfPos(); if not (p and ballPos) then return end
  local flat = Vector3.new(ballPos.X - p.X, 0, ballPos.Z - p.Z)
  if flat.Magnitude < 0.2 then return end
  local wantYaw = math.atan2(-flat.X, -flat.Z)
  local curYaw = HUB.wantYaw
  if not curYaw then
    local pc = proxyPart()
    local okc, cf = pcall(function() return pc and pc.CFrame end)
    if okc and cf then
      local lv = cf.LookVector
      curYaw = math.atan2(-lv.X, -lv.Z)
    else
      curYaw = wantYaw
    end
  end
  local diff = (wantYaw - curYaw + math.pi) % (2*math.pi) - math.pi
  diff = diff * math.clamp(smooth or CFG.Face.Smooth, 0.05, 1)
  local maxStep = (rate or CFG.Face.Rate) * (dt or 1/60)
  HUB.wantYaw = curYaw + math.clamp(diff, -maxStep, maxStep)
  HUB.faceAt = os.clock()
end

track(RunService.Heartbeat:Connect(function()
  if HUB.wantYaw and (os.clock() - (HUB.faceAt or 0)) > 0.25 then
    HUB.wantYaw = nil
  end
end))

local function defenseFaceTarget(ballPos, carrier, hoop)
  if carrier then
    local act = sAttr(carrier, "Action")
    if act == "Dunking" or act == "ContactLayup" then
      local cp = posOf(sChild(carrier, "HumanoidRootPart"))
      if cp then HUB.faceMode = "dunker"; return cp end
    end
  end
  -- РАЗВОРОТ ОТ КОЛЬЦА УБРАН.
  -- Он появился из гипотезы, что взгляд в кольцо мешает прыжку засчитаться как
  -- блок. Гипотеза не подтвердилась — в коде игры такой проверки нет вообще,
  -- а разворот наружу стоил нам мяча: смотреть надо туда, куда он летит.
  -- Вместе с ним ушла и ветка close shot: после удаления разворота обе её
  -- половины возвращали один и тот же ballPos, то есть каждый кадр считался
  -- hoopWeDefend и posOf ради ярлыка в диагностике.
  HUB.faceMode = "ball"
  return ballPos
end

local JP = {}

function JP.jumpV0()
  local g = Workspace.Gravity
  local apex = (HUB.jumpApex and (HUB.jumpApexN or 0) >= CFG.Grab.ApexMinN)
               and HUB.jumpApex or CFG.Grab.ApexGuess
  return math.sqrt(2 * g * math.max(apex, 0.1)), g
end

function JP.reachY()
  local r
  if HUB.jumpApex and (HUB.jumpApexN or 0) >= CFG.Grab.ApexMinN then
    r = HUB.jumpApex + CFG.Grab.ArmReach
  else

    r = CFG.Grab.ApexGuess + CFG.Grab.ArmReach
  end

  if CFG.Grab.ReachSet and CFG.Grab.ReachSet > 0 then return CFG.Grab.ReachSet end
  return math.clamp(r, CFG.Grab.ReachMin, CFG.Grab.ReachMax)
end

function JP.riseTo(dy)
  if type(dy) ~= "number" or dy <= 0 then return 0 end
  local v0, g = JP.jumpV0()
  local disc = v0*v0 - 2*g*dy
  if disc <= 0 then return v0/g end
  return (v0 - math.sqrt(disc)) / g
end

function JP.measureJumpLag(t0, y0)

  if sAttr(chr(), "InAir") == true then return end
  local pc = proxyPart()
  if pc then
    local ok, v = pcall(RDR.AssemblyLinearVelocity, pc)
    if ok and typeof(v) == "Vector3" and math.abs(v.Y) > 5 then return end
  end
  task.spawn(function()
    local deadline = t0 + 0.8
    while HUB.running and os.clock() < deadline do
      RunService.Heartbeat:Wait()

      local p = selfPos()
      local air = sAttr(chr(), "InAir")
      if air == true or (p and (p.Y - y0) > 0.15) then
        local lag = os.clock() - t0

        if lag < CFG.Grab.LagMin or lag > CFG.Grab.LagMax then
          HUB.jumpLagBad = (HUB.jumpLagBad or 0) + 1
          return
        end
        HUB.jumpLag = HUB.jumpLag and (HUB.jumpLag*0.7 + lag*0.3) or lag
        HUB.jumpLagN = (HUB.jumpLagN or 0) + 1

        task.spawn(function()
          local top, tEnd = 0, os.clock() + CFG.Grab.ApexWatch
          -- ВЫХОД ТОЛЬКО ПОСЛЕ ПОДТВЕРЖДЁННОГО ВЗЛЁТА.
          -- Здесь стояло "InAir == false and top > 0.5". InAir приходит с
          -- СЕРВЕРА, то есть с задержкой в пинг: в начале замера он ещё false
          -- от состояния до прыжка, и цикл выходил прямо на взлёте, едва
          -- подъём переваливал за полстуда. В дампе это jumpApex = 0.55
          -- вместо 3.7 и reachY = 4.05 — после чего мяч почти всегда
          -- оказывался "выше досягаемости" и прыжка не было вовсе.
          -- Сначала дожидаемся InAir == true, и только потом ловим приземление.
          local sawAir = false
          while HUB.running and os.clock() < tEnd do
            RunService.Heartbeat:Wait()
            local q = selfPos()
            if q then
              local up = q.Y - y0
              if up > top then top = up end
            end
            local air = sAttr(chr(), "InAir")
            if air == true then sawAir = true
            elseif sawAir and air == false then break end
          end
          if not sawAir then
            -- Взлёта не было вовсе: прыжок не прошёл, замерять нечего.
            HUB.jumpApexBad = (HUB.jumpApexBad or 0) + 1
          elseif top >= CFG.Grab.ApexMin and top <= CFG.Grab.ApexMax then
            HUB.jumpApex = HUB.jumpApex and (HUB.jumpApex*0.7 + top*0.3) or top
            HUB.jumpApexN = (HUB.jumpApexN or 0) + 1
          else
            HUB.jumpApexBad = (HUB.jumpApexBad or 0) + 1
          end
        end)
        return
      end
    end
    HUB.jumpLagMiss = (HUB.jumpLagMiss or 0) + 1
  end)
end

function JP.bodyRise(dy)
  return JP.riseTo(math.max((dy or 0) - CFG.Grab.ArmReach, 0))
end

function JP.jumpLead(dy)
  local ping = dataPing()
  local lag = HUB.jumpLag or (CFG.Grab.JumpLagFallback * ping)
  -- ЗАПАС НА РАННИЙ ПРЫЖОК.
  -- По журналу прыжков: у всех промахов мяч приходил РАНЬШЕ предсказанного
  -- (arrErr -38, -48, -57 мс, в среднем -32), а у попаданий позже (+60).
  -- То есть систематически опаздываем, и особенно там, где нужен реальный
  -- подъём: средний needRise у промахов 1.50 студа против 0.93 у попаданий.
  -- Это не подстройка на лету: величина фиксированная и задаётся игроком.
  return lag + JP.bodyRise(dy) + CFG.Grab.PingUp * ping + (CFG.Grab.JumpEarly or 0)
end

function JP.watchArrival(P, tPred, dy)
  if not (P and tPred) then return end
  local t0 = os.clock()
  local me0 = selfPos(); local y0 = me0 and me0.Y or 0
  local need = math.max((dy or 0) - CFG.Grab.ArmReach, 0)
  task.spawn(function()
    local bestD, bestT, handsAt = nil, nil, nil
    local deadline = t0 + tPred + 0.9
    while HUB.running and os.clock() < deadline do
      RunService.Heartbeat:Wait()
      local bp = (ballTrueNow(posOf(BALL.part), BALL.vel, BALL.stale))
      if bp then
        local d = (bp - P).Magnitude
        if not bestD or d < bestD then bestD, bestT = d, os.clock() end
      end
      if not handsAt then
        local mp = selfPos()
        if mp and (mp.Y - y0) >= need - 0.05 then handsAt = os.clock() end
      end
    end
    if not bestT then return end
    HUB.jumpLog = HUB.jumpLog or {}
    HUB.jumpLog[#HUB.jumpLog+1] = {
      arrErr  = math.floor(((bestT - t0) - tPred) * 1000 + 0.5),
      wantLead= math.floor(tPred * 1000 + 0.5),
      handsAt = handsAt and math.floor((handsAt - t0) * 1000 + 0.5) or nil,

      predErr = bestD and (math.floor(bestD * 10) / 10) or nil,

      reached = (handsAt ~= nil),
      needRise= math.floor(need * 10) / 10,
      dy      = math.floor((dy or 0) * 10) / 10,
      ping    = math.floor(dataPing() * 1000 + 0.5),
      -- Сколько мяч УЖЕ летел к моменту прыжка. Половина записей в журнале
      -- имеет wantLead = 0, то есть решение принималось, когда лететь было
      -- уже некуда. Здесь будет видно, опаздывает ли обнаружение.
      seenFor = BALL.tFlight and math.floor((os.clock() - BALL.tFlight) * 1000 + 0.5) or nil,
    }
    if #HUB.jumpLog > 10 then table.remove(HUB.jumpLog, 1) end
  end)
end

local function doJump(why, ballPos, dt, P, tPred, dy)
  if os.clock() - HUB.lastJump < CFG.Grab.JumpCD then return end

  if PBX.ballIsOurs() then HUB.blockWhy = "ball became ours, jump cancelled"; return end

  if type(dy) == "number" and dy > -900 and dy < CFG.Grab.NoJumpDy then
    HUB.blockWhy = ("no jump needed, ball only %+.1f up"):format(dy)
    return
  end
  HUB.lastJump = os.clock()
  local y0 = selfPos(); JP.measureJumpLag(os.clock(), y0 and y0.Y or 0)
  JP.watchArrival(P, tPred, dy)
  if ballPos then faceBall(ballPos, dt) end
  HUB.bypass = true
  pcall(Mt.FireServer, R.Shoot, { Shoot = true, Input = "E", UseSpace = true })
  pcall(Mt.FireServer, R.Jump)
  HUB.bypass = false
  task.delay(0.12, function()
    HUB.bypass = true
    pcall(Mt.FireServer, R.Shoot, { Shoot = false })
    HUB.bypass = false
  end)
  rep("SWAT: %s", tostring(why))

end

local SLIP = { Cone = 0.90, juke = { phase = nil, until_ = 0, doneAt = 0 } }

local SLIPLOG = {}
local slipPrev = {}
local function slipWatch()
  local nowW = os.clock()
  if nowW - (SLIP.watchAt or 0) < 0.05 then return end
  SLIP.watchAt = nowW
  local c = chr(); if not c then return end
  local cur = {
    act  = tostring(sAttr(c, "Action")),
    move = tostring(sAttr(c, "CanMove")),
    stun = tostring(sAttr(c, "Stunned")),
    dbg  = tostring(sAttr(c, "DodgeDebounce")),
    ldd  = tostring(sAttr(c, "LastDribbleDirection")),
  }
  for k, v in pairs(cur) do
    if slipPrev[k] ~= v then
      slipPrev[k] = v

      -- Этот цикл стоял ВНУТРИ перебора изменившихся атрибутов, то есть
      -- пересчитывал одно и то же по разу на каждый атрибут. Берём готовый
      -- покадровый снимок соперников.
      local me = selfPos()
      local near = nil
      if me then
        local npool, nn = foeSnap()
        for ni = 1, nn do
          local d = ((npool[ni].p - me) * FLAT).Magnitude
          if not near or d < near then near = d end
        end
      end
      if near and near <= 8 then
        SLIPLOG[#SLIPLOG+1] = ("%.2f %s=%s at %.1f stds"):format(os.clock(), k, v, near)
        if #SLIPLOG > 120 then table.remove(SLIPLOG, 1) end
        HUB.slipHit = os.clock()
        HUB.slipHitAct = ("%s=%s"):format(k, v)
      end
    end
  end
end
track(RunService.Heartbeat:Connect(slipWatch))

function SLIP.slipContactRadius(other)
  local r = 2.0
  local root = sChild(other, "HumanoidRootPart")
  if root then
    local ok, sz = pcall(RDR.Size, root)
    if ok and typeof(sz) == "Vector3" then r = sz.X end
  end
  local mul = 1.2
  local myAct, hisAct = sAttr(chr(), "Action"), sAttr(other, "Action")
  if sAttr(chr(), "InPost") == true or sAttr(other, "InPost") == true then
    r, mul = 2.45, 1.0
  elseif myAct == "Blocking" then
    mul = 0.7
  elseif sAttr(other, "Screening") == true or sAttr(chr(), "Screening") == true then
    mul = 0.8
  elseif hisAct == "Dunking" or myAct == "Dunking" then
    mul = 1.1
  elseif hisAct == "Gathering" or myAct == "Gathering" then
    r, mul = 2.0, 1.0
  end
  return r * mul
end

function SLIP.keepDist(other)  return SLIP.slipContactRadius(other) * 1.25 end

-- Во сколько радиусов контакта начинать обходить. Было жёстко 2.60, то есть
-- около шести студов, и увод начинался задолго до реальной угрозы.
function SLIP.steerFrom(other)
  return SLIP.slipContactRadius(other) * (CFG.Move.Slip.StartMul or 2.0)
end

function SLIP.slipBlocker(me, dir)
  local best, bd, br = nil, nil, nil
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      local p = posOf(sChild(c, "HumanoidRootPart"))
      if p then
        local to = (p - me) * FLAT
        local d = to.Magnitude
        local rad = SLIP.slipContactRadius(c)
        if d > 0.1 and d <= SLIP.steerFrom(c) then

          if dir and to.Unit:Dot(dir) > 0.40 then
            if not bd or d < bd then best, bd, br = c, d, rad end
          end
        end
      end
    end
  end
  return best, bd, br
end

function SLIP.slipAdjust(dir, me, foe)
  local fp = posOf(sChild(foe, "HumanoidRootPart")); if not fp then return dir end
  local to = ((fp - me) * FLAT)
  if to.Magnitude < 0.1 then return dir end
  to = to.Unit
  local dot = dir:Dot(to)

  -- Толчок ставится ТОЛЬКО при лобовом входе (в коде игры dot > 0.99, конус ~8
  -- градусов). Если игрок УЖЕ идёт мимо, отклонять нечего: любое вмешательство
  -- здесь просто уводит его с курса. Cone = 0.90 (~25 градусов) — с запасом.
  if dot < SLIP.Cone then return dir end

  -- ИДЁМ ПОЧТИ В ЛОБ: отклоняем на МИНИМАЛЬНЫЙ угол, чтобы выйти из конуса
  -- толчка, СОХРАНЯЯ движение вперёд. Прошлая версия внутри keepDist возвращала
  -- чистый перпендикуляр (right - to*0.35, около 90 градусов) — это и есть
  -- «кружит вокруг врага и не могу идти»: forwardValue падал к нулю, игра
  -- резала скорость, а курс игрока подменялся боковым. Достаточно Angle
  -- градусов (по умолчанию 18 > 8), проекция на ввод остаётся большой.
  local right = Vector3.new(-to.Z, 0, to.X)
  local sign = (right:Dot(dir) >= 0) and 1 or -1
  -- уводим в ту сторону, куда игрок и так клонится; если строго в лоб —
  -- в сторону спины защитника по его рысканью
  if math.abs(right:Dot(dir)) < 0.05 then
    local okf, fcf = pcall(function()
      local r = sChild(foe, "HumanoidRootPart"); return r and r.CFrame
    end)
    if okf and fcf and right:Dot(fcf.LookVector) > 0 then sign = -1 end
  end
  local a = math.rad(CFG.Move.Slip.Angle) * sign
  local ca, sa = math.cos(a), math.sin(a)
  local nd = Vector3.new(dir.X*ca - dir.Z*sa, 0, dir.X*sa + dir.Z*ca)
  HUB.slipKeep = os.clock()
  return (nd.Magnitude > 0.05) and nd.Unit or dir
end

local function segClearance(me, h, len, p)
  local to = (p - me) * FLAT
  local t = math.clamp(to:Dot(h), 0, len)
  return ((me + h * t) - p) * FLAT
end

function SLIP.barriers()
  local now = os.clock()
  if SLIP.bList and now - (SLIP.bAt or 0) < 3 then return SLIP.bList end
  SLIP.bAt = now
  local out = {}
  local court = PK.court
  if not court then

    local mine = sAttr(chr(), "CourtNumber")
    local courts = sChild(sChild(Workspace, "Map"), "Courts")

    local ok, kids = false, nil
    if courts then ok, kids = pcall(function() return courts:GetChildren() end) end
    if ok and kids then
      for _, c in ipairs(kids) do
        local okn, num = pcall(function() return c:GetAttribute("CourtNumber") end)
        if okn and num ~= nil and num == mine then court = c; break end
      end
    end
  end
  if court then
    local ok, kids = pcall(Mt.GetDescendants, court)
    if ok then
      for _, d in ipairs(kids) do
        local okp, par = pcall(RDR.Parent, d)
        if okp and par and par.Name == "Barriers" and d:IsA("BasePart") then

          local okg, gp = pcall(RDR.Parent, par)
          if not (okg and gp and gp.Name == "Bench") then out[#out+1] = d end
        end
      end
    end
  end
  SLIP.bList = out
  return out
end

function SLIP.pastBarrier(me, q)
  local list = SLIP.barriers()
  if #list == 0 then return false end
  SLIP.bRP = SLIP.bRP or RaycastParams.new()
  SLIP.bRP.FilterType = Enum.RaycastFilterType.Include
  SLIP.bRP.FilterDescendantsInstances = list

  pcall(function() SLIP.bRP.RespectCanCollide = true end)
  local seg = (q - me) * FLAT
  if seg.Magnitude < 0.1 then return false end
  local ok, hit = pcall(function() return Workspace:Raycast(me, seg, SLIP.bRP) end)
  return ok and hit ~= nil
end

SLIP.vtrack = {}
function SLIP.foeVel(c, p, now)
  local e = SLIP.vtrack[c]
  if not e then
    SLIP.vtrack[c] = { p = p, v = Vector3.zero, t = now, seen = now }
    return Vector3.zero
  end
  local dt = now - e.t
  if dt >= 0.011 then
    local raw = ((p - e.p) * FLAT) / dt

    if raw.Magnitude > 45 then raw = Vector3.zero end
    e.v = e.v:Lerp(raw, 0.35)
    e.p, e.t = p, now
  end
  e.seen = now
  return e.v
end

function SLIP.feintDir(dir, me)
  local F = CFG.Move.Slip
  local now0 = os.clock()
  local J = SLIP.juke

  if now0 - (SLIP.vClean or 0) > 5 then
    SLIP.vClean = now0
    for k, e in pairs(SLIP.vtrack) do
      if now0 - (e.seen or 0) > 5 then SLIP.vtrack[k] = nil end
    end
  end

  local foes, n, nearest, stanceNear = {}, 0, 1e9, 1e9
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      local p = posOf(sChild(c, "HumanoidRootPart"))
      if p then
        local d = ((p - me) * FLAT).Magnitude
        if d > 0.1 and d <= F.ReactRadius then
          local st = (sAttr(c, "HoldingG") == true)
          n += 1
          foes[n] = { p = p, d = d, stance = st,
                      v = SLIP.foeVel(c, p, now0),

                      spd = st and F.FoeSpeedStance or F.FoeSpeedBase,
                      w = st and F.StanceWeight or 1,
                      body = SLIP.keepDist(c) }
          if d < nearest then nearest = d end
          if st and d < stanceNear then stanceNear = d end
        end
      end
    end
  end
  HUB.slipFoes = n
  HUB.slipNear = (n > 0) and nearest or nil

  local dtP = math.clamp(now0 - (J.pAt or now0), 0, 0.1)
  J.pAt = now0
  local load = 0
  if stanceNear < F.StanceRange then
    load = 1 - stanceNear / F.StanceRange
  elseif nearest < F.KeepGap then
    load = 0.5 * (1 - nearest / F.KeepGap)
  end
  J.press = math.clamp((J.press or 0)
    + dtP * ((load > 0) and (F.PressRise * load) or -F.PressFall), 0, 1)
  HUB.slipPress = J.press

  if n == 0 or (stanceNear > F.StanceRange and nearest > F.KeepGap) then
    HUB.slipJuke, HUB.slipSep = nil, nil
    return dir
  end

  local hp = ourGoalPos()
  local dist = hp and ((me - hp) * FLAT).Magnitude or nil
  if dist and dist > F.ZoneRad + F.ZoneSlack then
    HUB.slipJuke = ("out of range (%.0f/%.0f), not feinting"):format(dist, F.ZoneRad)
    return dir
  end

  local prev = (J.aim and now0 - (J.aimAt or 0) < F.CommitTime) and J.aim or nil
  local tArr = F.StepOut / math.max(F.OurSpeed, 1)

  local maxSpd = 0
  for i = 1, n do if foes[i].spd > maxSpd then maxSpd = foes[i].spd end end
  local gain = math.max(1.0, math.min(F.Open, F.React * maxSpd * 2))

  local function sepAt(f, q)
    local lag  = math.min(F.React, tArr)
    local pl   = f.p + f.v * lag
    local to   = (q - pl) * FLAT
    local d    = to.Magnitude
    local rest = tArr - lag
    if rest <= 0 or d < 1e-3 then return d end
    return d - math.min(f.spd * rest, d)
  end

  local function score(h)
    local q = me + h * F.StepOut

    local open = F.Open
    for i = 1, n do
      local f = foes[i]
      local s = sepAt(f, q) / f.w
      if s < open then open = s end
    end
    local s = F.OpenWeight * math.min(open / gain, 1)

    for i = 1, n do
      local f = foes[i]
      local gap = segClearance(me, h, F.StepOut, f.p).Magnitude
      if gap < f.body then s = s - F.LaneWeight * ((f.body - gap) / f.body) end
    end

    s = s + F.InputWeight * h:Dot(dir)
    if prev then s = s + F.Commit * h:Dot(prev) end
    if dist then
      local outd = ((q - hp) * FLAT).Magnitude
      if outd > F.ZoneRad then
        s = s - F.ZoneWeight * ((outd - F.ZoneRad) / math.max(F.ZoneRad, 1))
      end
    end

    if SLIP.pastBarrier(me, q) then s = s - 1e6 end
    return s, open
  end

  local bs, bopen = score(dir)
  local best = dir

  local stepA, maxA = math.rad(F.FeintStep), math.rad(F.MaxTurn)
  local a = stepA
  while a <= maxA + 1e-6 do
    for _, sgn in ipairs({ 1, -1 }) do
      local ang = a * sgn
      local ca, sa = math.cos(ang), math.sin(ang)
      local h = Vector3.new(dir.X*ca - dir.Z*sa, 0, dir.X*sa + dir.Z*ca)
      if h.Magnitude > 1e-3 then
        h = h.Unit
        local s, op = score(h)
        if s > bs then best, bs, bopen = h, s, op end
      end
    end
    a = a + stepA
  end

  if best:Dot(dir) < 0.05 then best = dir end
  J.aim, J.aimAt, J.want = best, now0, dir
  HUB.slipSep = bopen
  J.why = ("sep %.1f, turned %.0f deg, nearest %.1f, press %.2f%s"):format(
    bopen, math.deg(math.acos(math.clamp(best:Dot(dir), -1, 1))), nearest, J.press,
    (stanceNear < 1e8) and (", stance at " .. ("%.1f"):format(stanceNear)) or "")
  HUB.slipJuke = J.why
  if dist then
    HUB.slipZone = ("%.0f/%.0f from our rim"):format(dist, F.ZoneRad)
  end
  return best
end


local MoveHooked = {}
local function installMoveHook()
  if next(MoveHooked) then return true end
  if not (filtergc and hookfunction) then
    HUB.pmSrc = "no filtergc/hookfunction"; return false
  end
  local okl, list = pcall(filtergc, "function", { Name = "UpdateMoveDirection" }, false)
  if not (okl and type(list) == "table" and #list > 0) then
    HUB.pmSrc = "UpdateMoveDirection not in GC"; return false
  end
  local n = 0
  for _, f in ipairs(list) do
    if type(f) == "function" and not MoveHooked[f] then
      local orig
      local okf = pcall(function()
        orig = hookfunction(f, function(self, dt)
          local r = orig(self, dt)
          if type(self) ~= "table" or rawget(self, "WalkSpring") == nil then return r end
          return PBX.moveBody(self, dt, r)
        end)
      end)
      if okf and orig then MoveHooked[f] = orig; n += 1 end
    end
  end
  if n == 0 then HUB.pmSrc = "hookfunction failed"; return false end
  HUB.pmCount = n
  HUB.pmSrc = ("UpdateMoveDirection (hookfunction x%d)"):format(n)
  return true
end


-- Правда ли, что мы ведём мяч прямо на кольцо и вот-вот будем данковать.
function PBX.drivingRim(own)
  local R = CFG.Move.RimFree
  if not (R and R > 0) then return false end
  if not hasBall(chr()) then return false end
  local me = selfPos(); if not me then return false end
  local hp = nearestHoop(me); if not hp then return false end
  local to = (hp - me) * FLAT
  local d = to.Magnitude
  if d > R then return false end
  if typeof(own) ~= "Vector3" or own.Magnitude < 0.1 then return true end
  if d < 0.1 then return true end
  -- Идём именно К кольцу, а не мимо: иначе увод у щита остался бы полезным.
  return to.Unit:Dot(own.Unit) > 0.3
end

function PBX.moveBody(self, dt, r)

      if zeroActive() and type(self) == "table"
         and rawget(self, "MoveDirection") ~= nil then
        self.MoveDirection = Vector3.new()
        self.forwardValue, self.rightValue = 0, 0
        return r
      end
      local ov = HUB.moveWorld
      local bent = false

      if ov and HUB.moveNeedInput then
        local own = rawget(self, "MoveDirection")
        if typeof(own) ~= "Vector3" or own.Magnitude < 0.1 then ov = nil end
      end

      -- ПОСТОЯННЫЙ УВОД ТЕПЕРЬ ВКЛЮЧАЕТСЯ ОТДЕЛЬНО.
      -- Он висел на общем выключателе Anti Defense: включаешь отшаг перед
      -- броском — и молча получаешь вечное искривление курса, которое никак
      -- не отключить. В дампе Contact Slip выключен (slipWhy = "off"), а от
      -- соперников всё равно уводит — это была именно эта ветка.
      if CFG.AntiDef.Enabled and CFG.AntiDef.PushOn
         and not ov and type(self) == "table" then
        local own = rawget(self, "MoveDirection")
        local skip = PBX.drivingRim(own) or PBX.contactOff()
        if skip then
          HUB.antiWhy = PBX.contactOff()
            and ("no contact during %s, not bending"):format(tostring(sAttr(chr(), "Action")))
            or "driving the rim, course left alone"
        end
        if typeof(own) == "Vector3" and own.Magnitude > 0.1 and not skip then
          local me2 = selfPos()
          if me2 and ((not CFG.AntiDef.OnlyBall) or hasBall(chr())) then
            local foe, fd = nil, nil
            local pool, np = foeSnap()
            for i = 1, np do
              local e = pool[i]
              local d = ((e.p - me2) * FLAT).Magnitude
              local eff = (CFG.AntiDef.Stance and e.g) and (d * 0.6) or d
              if d <= CFG.AntiDef.Keep and (not fd or eff < fd) then foe, fd = e.p, eff end
            end
            if foe then
              local away = ((me2 - foe) * FLAT)
              if away.Magnitude > 0.1 then
                local mix = (own * FLAT)
                if mix.Magnitude > 0.05 then

                  local w = CFG.AntiDef.Push
                            * (0.35 + 0.65 * (1 - math.min(fd / CFG.AntiDef.Keep, 1)))
                  local nd = (mix.Unit * (1 - w) + away.Unit * w)
                  if nd.Magnitude > 0.05 then
                    self.MoveDirection = nd.Unit * own.Magnitude
                    bent = true

                    local okr, root = pcall(RDR.Root, self)
                    if okr and root then
                      local okc, cf = pcall(RDR.CFrame, root)
                      if okc and cf then
                        self.forwardValue = cf.LookVector:Dot(nd.Unit)
                        self.rightValue   = cf.RightVector:Dot(nd.Unit)
                      end
                    end
                    HUB.antiWhy = ("keeping %.1f stds, mix %.2f"):format(fd, w)
                    HUB.antiAt = os.clock()
                  end
                end
              end
            else
              HUB.antiWhy = "nobody covering"
            end
          end
        end
      end

      if not CFG.Move.Slip.Enabled then HUB.slipWhy = "off"
      elseif ov then HUB.slipWhy = "another feature is steering: " .. tostring(HUB.moveOwner)
      elseif not hasBall(chr()) then HUB.slipWhy = "no ball in our hands"
      end
      if CFG.Move.Slip.Enabled and hasBall(chr()) and not ov and type(self) == "table" then
        local own = rawget(self, "MoveDirection")
        if typeof(own) ~= "Vector3" or own.Magnitude <= 0.1 then
          HUB.slipWhy = "standing still, nothing to redirect"
        end
        local atRim = PBX.drivingRim(own)
        if atRim then
          HUB.slipWhy = ("driving the rim, course left alone (inside %.0f stds)")
            :format(CFG.Move.RimFree)
        end
        local noPush = CFG.Move.Slip.SkipNoContact and PBX.contactOff()
        if noPush then
          HUB.slipWhy = ("no contact during %s, going straight through")
            :format(tostring(sAttr(chr(), "Action")))
        end
        if typeof(own) == "Vector3" and own.Magnitude > 0.1
           and not atRim and not noPush then
          local me = selfPos()
          if me then
            local dir = (own * FLAT)
            if dir.Magnitude > 0.05 then
              HUB.slipWhy = tostring(CFG.Move.Slip.Mode)
              dir = dir.Unit

              local nd
              if CFG.Move.Slip.Mode == "Feint" then
                nd = SLIP.feintDir(dir, me)
                local foe = SLIP.slipBlocker(me, nd or dir)
                if foe then nd = SLIP.slipAdjust(nd or dir, me, foe) end
              else
                local foe = SLIP.slipBlocker(me, dir)
                if foe then nd = SLIP.slipAdjust(dir, me, foe) end
              end
              -- ИМЯ ЗДЕСЬ БЫЛО ТОЖЕ bent, И ОНО ЗАТЕНЯЛО ВНЕШНИЙ ФЛАГ.
              -- Внешний bent объявлен выше и решает, сообщить ли серверу
              -- фактическое направление. Присваивание в этой ветке уходило в
              -- локальную копию, сервер оставался при исходном вводе, и мы
              -- получали ровно тот рассинхрон, из-за которого игрок замирает.
              local amount = nd and (nd - dir).Magnitude or 0
              HUB.slipWhy = ("%s: bent %.2f, %d foes"):format(
                tostring(CFG.Move.Slip.Mode), amount, HUB.slipFoes or -1)
              if nd and amount > 0.01 then
                self.MoveDirection = nd * own.Magnitude
                bent = true
                HUB.slipOn = os.clock()
                local okr, root = pcall(RDR.Root, self)
                if okr and root then
                  local okc, cf = pcall(RDR.CFrame, root)
                  if okc and cf then
                    self.forwardValue = cf.LookVector:Dot(nd)
                    self.rightValue   = cf.RightVector:Dot(nd)
                  end
                end
              end
            end
          end
        end
      end
      if ov and type(self) == "table" and rawget(self, "MoveDirection") ~= nil then
        self.MoveDirection = ov
        local okr, root = pcall(RDR.Root, self)
        if okr and root then
          local okc, cf = pcall(RDR.CFrame, root)
          if okc and cf then
            self.forwardValue = cf.LookVector:Dot(ov)
            self.rightValue   = cf.RightVector:Dot(ov)
          end
        end
      end

  -- ГОВОРИМ СЕРВЕРУ ТО, КУДА РЕАЛЬНО ИДЁМ.
  -- Movement_ModuleScript:177 отправляет серверу ввод v46 ДО нашего хука, и
  -- если мы после этого гнём MoveDirection, сервер продолжает считать, что мы
  -- идём по исходному вводу. Расхождение он правит сам — в дампе это
  -- Action="Moving" + CanMove=false + ForceMoveDirection=(0,0,0), состояние,
  -- из которого игра не выходит (Base:236 делает ранний return). Дешевле не
  -- расходиться: шлём фактическое направление, но только при заметной смене,
  -- чтобы не спамить канал.
  if bent then
    local fin = rawget(self, "MoveDirection")
    if typeof(fin) == "Vector3" and fin.Magnitude > 0.05 then
      local u = fin.Unit
      if (not HUB.bentSent) or (u - HUB.bentSent).Magnitude > 0.12 then
        HUB.bentSent = u
        HUB.bypass = true
        pcall(Mt.FireServer, R.Move, u)
        HUB.bypass = false
      end
    end
  elseif HUB.bentSent then
    HUB.bentSent = nil
  end
  return r
end

local function removeMoveHook()
  HUB.moveWorld, HUB.moveAt = nil, nil
  if restorefunction then
    for f, _ in pairs(MoveHooked) do pcall(restorefunction, f) end
  end
  MoveHooked = {}
  HUB.pmCount = 0
end

local function reinstallMoveHook()
  MoveHooked = {}
  return installMoveHook()
end
track({ Disconnect = removeMoveHook })

-- silent = НЕ ТРОГАТЬ ВВОДНЫЕ РЕМОУТЫ ИГРЫ.
-- Отшаг Anti Defense идёт ВО ВРЕМЯ броска, а Move и Sprint — это те же каналы,
-- которыми игрок отменяет удар и меняет тип гатера (Backstep, Sidestep,
-- Hesitation и прочие лежат в Assets/Animations/Gathers и выбираются по вводу).
-- Прислав туда своё направление и Sprint=false посреди замаха, мы сообщаем
-- серверу «игрок передумал». Двигаться ради этого не нужно: скорость мы пишем
-- прямо в MovementVelocity, и она уезжает штатной репликацией персонажа.
local function steerToDir(dir, sprint, owner, silent)

  if installMoveHook() then

    if dir.Magnitude <= 0.05 then
      HUB.moveWorld, HUB.moveAt, HUB.moveOwner = nil, nil, nil
      HUB.moveNeedInput = nil
      return
    end
    HUB.moveWorld = dir
    HUB.moveAt = os.clock()
    HUB.moveOwner = owner or "?"

    HUB.moveNeedInput = (owner == "defense") and (CFG.Defense.Mode == "Hook")
    HUB.moveSrc = tostring(HUB.pmSrc)
    HUB.cmdDir, HUB.cmdAt = dir, os.clock()
  else
    HUB.moveSrc = "remote only: " .. tostring(HUB.pmSrc)
  end

  if not silent then
    local changed = (not HUB.lastDir) or (dir - HUB.lastDir).Magnitude > 0.08
    if changed then
      HUB.bypass = true
      pcall(Mt.FireServer, R.Move, dir)
      HUB.bypass = false
      HUB.lastDir = dir
    end

    if sprint ~= HUB.sprintOn then
      HUB.bypass = true
      pcall(Mt.FireServer, R.Sprint, sprint and true or false)
      HUB.bypass = false
      HUB.sprintOn = sprint and true or false
    end
    HUB.steering = true
  end
end

function stopSteerSoft(owner)
  if owner and HUB.moveOwner and HUB.moveOwner ~= owner then return end
  HUB.moveWorld, HUB.moveAt, HUB.moveOwner = nil, nil, nil
  HUB.moveNeedInput = nil
end

track(RunService.Heartbeat:Connect(function()
  if HUB.moveWorld == nil then return end
  if (os.clock() - (HUB.moveAt or 0)) > 0.25 then
    HUB.moveWorld = nil
    HUB.moveSrc = nil
    return
  end

  local m = HUB.mov
  if not (m and HUB.cmdDir and HUB.cmdDir.Magnitude > 0.5) then return end
  if (os.clock() - (HUB.cmdAt or 0)) < 0.12 then return end
  local okd, md = pcall(RDR.MoveDirection, m)
  if not (okd and typeof(md) == "Vector3") then return end
  HUB.moveSeen = math.floor(md.Magnitude*100)/100
  if md.Magnitude > 0.3 and md.Unit:Dot(HUB.cmdDir.Unit) > 0.5 then
    HUB.moveBad, HUB.moveOK = 0, true
    return
  end
  HUB.moveBad = (HUB.moveBad or 0) + 1
  HUB.moveOK = false

  if HUB.moveBad >= 12 and not HUB.reHooked then
    HUB.reHooked = true
    local okr = reinstallMoveHook()
    notify(okr and ("input hook re-attached: "..tostring(HUB.pmSrc))
               or  "input hook not working: UpdateMoveDirection missing")
  end
end))

track(RunService.Heartbeat:Connect(function()
  local c = chr(); if not c then return end
  local m = HUB.mov
  local want = m and rawget(m, "MoveDirection")
  local hrp = sChild(c, "HumanoidRootPart")
  local vel = hrp and posOf(hrp) and (function()
    local ok, v = pcall(RDR.AssemblyLinearVelocity, hrp)
    return ok and v or nil
  end)() or nil
  local wantMag = (typeof(want)=="Vector3") and want.Magnitude or 0
  local velMag = vel and (vel*FLAT).Magnitude or 0
  if wantMag > 0.3 and velMag < 1.5 and sAttr(c, "CanMove") ~= false then
    HUB.stuckSince = HUB.stuckSince or os.clock()
    if os.clock() - HUB.stuckSince > 0.3 then
      HUB.stuckFor = os.clock() - HUB.stuckSince
      HUB.stuckWho = (zeroActive() and "zeroSpread")
        or (HUB.moveWorld and ("steer:"..tostring(HUB.moveOwner)))
        or (CFG.Move.Slip.Enabled and hasBall(c) and ("slip:"..CFG.Move.Slip.Mode))
        or (CFG.AntiDef.Enabled and hasBall(c) and "antidef")
        or "unknown"
      HUB.stuckVelHook = (HUB.velHooks or 0) > 0
    end
  else
    HUB.stuckSince, HUB.stuckFor, HUB.stuckWho = nil, nil, nil
    HUB.stuckVelHook = nil
  end
end))

local function steerTo(pt, owner)
  local me = selfPos(); if not me then return end
  local d = (pt - me) * FLAT
  if d.Magnitude < 1 then stopSteerSoft(owner); return end
  steerToDir(d.Unit, CFG.Grab.Sprint and true or false, owner)
end

local function stopSteer(owner)
  if owner and HUB.moveOwner and HUB.moveOwner ~= owner then return end
  HUB.moveWorld, HUB.moveAt, HUB.moveOwner = nil, nil, nil
  HUB.moveNeedInput = nil
  HUB.defDir = nil
  if not HUB.steering then return end
  HUB.steering = nil
  HUB.lastDir = nil

  local real = Vector3.new()
  local m = HUB.mov
  if m then
    local okd, d = pcall(function() return rawget(m, "lastMoveDirection") end)
    if okd and typeof(d) == "Vector3" then real = d end
  end
  local wantSprint = false
  pcall(function() wantSprint = UIS:IsKeyDown(Enum.KeyCode.LeftShift) end)
  if HUB.sprintAuto then wantSprint = true end
  HUB.bypass = true
  pcall(Mt.FireServer, R.Move, real)
  if HUB.sprintOn ~= wantSprint then
    pcall(Mt.FireServer, R.Sprint, wantSprint)
    HUB.sprintOn = wantSprint
  end
  HUB.bypass = false
end

function PBX.probe()
  local out = {}
  local function add(f, ...) out[#out+1] = select("#",...)>0 and f:format(...) or f end

  local RS = cloneref(game:GetService("ReplicatedStorage"))
  local root = sChild(sChild(RS, "Aero"), "AeroRemoteServices")
  if not root then return "AeroRemoteServices not found" end

  local function inv(f, ...)
    local m = rawget(Mt, "InvokeServer")
    if type(m) ~= "function" then
      local ok, got = pcall(RDR.InvokeServer, f)
      if ok and type(got) == "function" then Mt.InvokeServer = got; m = got end
    end
    if type(m) ~= "function" then error("no InvokeServer", 0) end
    return m(f, ...)
  end

  local function try(label, f, ...)
    local args = table.pack(...)
    local t0 = os.clock()
    local ok, res = pcall(function() return inv(f, table.unpack(args, 1, args.n)) end)
    local ms = (os.clock() - t0) * 1000
    if not ok then
      add("  [blocked] %-38s %s", label, tostring(res):sub(1, 80)); return nil
    end
    if type(res) == "table" then
      local n, keys = 0, {}
      for k in pairs(res) do n += 1; if #keys < 14 then keys[#keys+1] = tostring(k) end end
      add("  [OPEN]    %-38s table %d keys: %s  (%.0f ms)", label, n, table.concat(keys, ", "), ms)
    else
      add("  [OPEN]    %-38s %s = %s  (%.0f ms)", label, typeof(res), tostring(res):sub(1,50), ms)
    end
    return res
  end

  add("=== remote probe %s ===", os.date("%H:%M:%S"))

  local okk, svcs = pcall(function() return root:GetChildren() end)
  if okk then
    for _, svc in ipairs(svcs) do
      local okc, kids = pcall(function() return svc:GetChildren() end)
      if okc then
        for _, r in ipairs(kids) do
          local isRF = false
          pcall(function() isRF = r:IsA("RemoteFunction") end)
          if isRF then
            local nm = svc.Name .. ":" .. r.Name

            local deny = nm:find("Teleport") or nm:find("Join") or nm:find("Load")
                      or nm:find("Leave")    or nm:find("Party") or nm:find("Kick")
                      or nm:find("Buy")      or nm:find("Purchase") or nm:find("Dye")
                      or nm:find("Roll")     or nm:find("Equip") or nm:find("Use")
                      or nm:find("Start")    or nm:find("Verify") or nm:find("Upgrade")
                      or nm:find("Change")   or nm:find("Set")   or nm:find("Update")
                      or nm:find("Command")  or nm:find("Toggle") or nm:find("Spawn")
                      or nm:find("Select")   or nm:find("Admin")
            if deny then
              add("  [skipped] %-38s could change session or account", nm)
            else
              try(nm, r)
            end
          end
        end
      end
    end
  end

  local dbg = sChild(sChild(root, "DebugService"), "Get")
  if dbg then
    for _, path in ipairs({ "Modules/Config", "Modules", "Services", "Config" }) do
      local cfg = try("DebugService:Get(" .. path .. ")", dbg, path)
      if type(cfg) == "table" then
        local seen = 0
        local function walk(t, pre, d)
          if d > 4 or seen > 120 then return end
          for k, v in pairs(t) do
            local key = tostring(k)
            local pk = pre .. "." .. key
            if type(v) == "table" then walk(v, pk, d + 1)
            elseif key:find("Contest") or key:find("Green") or key:find("Block")
                or key:find("Radius") or key:find("Accuracy") or key:find("Make") then
              seen += 1; add("      %s = %s", pk, tostring(v))
            end
          end
        end
        pcall(walk, cfg, path, 0)
      end
    end
  else
    add("  DebugService.Get not present")
  end

  add("=== end. [OPEN] = server answered ===")
  local text = table.concat(out, "\n")
  pcall(function()
    if isfolder and not isfolder(CFG.Debug.Folder) then makefolder(CFG.Debug.Folder) end
    writefile(CFG.Debug.Folder .. "/probe.txt", text)
  end)
  pcall(function() if setclipboard then setclipboard(text) end end)
  return text
end

function PBX.legitStep(g, hp)
  local A = CFG.AntiDef
  -- Пеший отшаг и BackTP делят один вход: те же React и StopAt, разный способ.
  if not (A.Enabled and A.PreShot
          and (A.Mode == "Legit" or A.Mode == "BackTP")) then return end
  -- ЗДЕСЬ СТОЯЛ ВЫХОД ПО CanMove == false, И ОН УБИВАЛ ВСЮ ФУНКЦИЮ.
  -- Бросок входит в IsInCoreAction (GameUtil:70), на нём сервер и ставит
  -- CanMove = false. То есть проверка отменяла отшаг ровно в тот момент,
  -- ради которого он существует. Двигаться это не мешает: скорость мы
  -- пишем сами в хуке UpdateVelocity, а MaxForce (Base:230) выставляется
  -- игрой ДО раннего return и от CanMove не зависит.

  local function nearestFoe(mp)
    local foe, best, real = nil, nil, nil
    local pool, np = foeSnap()
    for i = 1, np do
      local e = pool[i]
      local r = ((e.p - mp) * FLAT).Magnitude
      -- держащий стойку опаснее: для ВЫБОРА цели он «ближе», чем есть.
      -- Тумблер тот же, что у постоянного увода, иначе одна галка влияла
      -- бы на одну ветку и молчала в двух других.
      local d = r / ((A.Stance and e.g) and A.StanceWeight or 1)
      if not best or d < best then foe, best, real = e.p, d, r end
    end
    return foe, real
  end

  local startPos = selfPos()
  if not startPos then return 0, nil, "no position" end
  local foe0, gap0 = nearestFoe(startPos)

  -- ЗАПУСК ПО РЕАКЦИИ, ОСТАНОВКА ПО ДОСТАТОЧНОСТИ — ЭТО РАЗНЫЕ ЧИСЛА.
  -- Раньше обе роли играл один LegitGap = 8: цикл выходил, как только разрыв
  -- доставал до восьми. Враг в семи студах — отошли ровно один и встали, враг
  -- в девяти — не двинулись вообще. Отсюда «отходит на 2-3 студа и только
  -- когда впритык». Теперь React решает, СТОИТ ЛИ уходить, а StopAt — когда
  -- уже хватит; между ними отшаг идёт весь свой бюджет времени.
  if not foe0 then return 0, nil, "nobody near" end
  if gap0 >= A.React then
    return 0, gap0, ("nobody within %.0f stds"):format(A.React)
  end

  local t0 = os.clock()

  -- ДРИББЛ-ОТХОД. Keyboard_ModuleScript:51 шлёт Dribble:Fire(combo, sprint,
  -- lastMoveDirection), а Dribbling_ModuleScript.Input сопоставляет комбинации
  -- ходам: "X" это StepBack на обе руки, ровно разрыв дистанции. Шлём ОДИН раз
  -- и ДО того, как уйдёт пакет броска: во время замаха любой ввод меняет тип
  -- гатера, этому мы уже научились на спринте.
  if A.Dribble and R.Drib and not PBX.shotBusy() then
    if (os.clock() - (HUB.antiDribAt or 0)) > A.DribbleCD then
      HUB.antiDribAt = os.clock()
      local away = (startPos - foe0) * FLAT
      away = (away.Magnitude > 0.1) and away.Unit or Vector3.new(0,0,1)
      HUB.bypass = true
      pcall(Mt.FireServer, R.Drib, A.DribbleCombo, false, away)
      HUB.bypass = false
      HUB.antiDrib = ("dribble %s away"):format(tostring(A.DribbleCombo))
    end
  end

  -- BACKTP: то же, что Legit, но одним шагом.
  -- Цель считается той же парой React/StopAt, просто вместо ходьбы ставим
  -- позицию сразу. Ходьба упирается в игровой потолок скорости, телепорт нет.
  if A.Mode == "BackTP" then
    local moved = 0
    local pc = proxyPart()
    if pc and physAllowed() then
      local away = (startPos - foe0) * FLAT
      away = (away.Magnitude > 0.1) and away.Unit or Vector3.new(0,0,1)
      local want = math.min(A.StopAt - gap0, A.BackTPMax)
      if want > 0 then
        local okc, cf = pcall(RDR.CFrame, pc)
        if okc and cf then
          tpProxy(pc, cf + away * want)
          moved = want
          HUB.antiShot = ("back teleport: gap %.1f -> %.1f (%.1f stds)")
            :format(gap0, gap0 + want, want)
        end
      end
    end
    if moved == 0 then HUB.antiShot = "back teleport blocked (server holds the position)" end
    if A.LegitFace and hp then faceBall(hp, 1/60, A.FaceRate, A.FaceSmooth) end
    return moved, gap0, "back teleport"
  end

  if A.Speed and A.Speed > 0 then
    HUB.antiSpeed = A.Speed
    HUB.antiSpeedUntil = t0 + A.StepTime + 0.1
  end

  local gap = gap0
  while HUB.running and HUB.gen == g and os.clock() - t0 < A.StepTime do
    local mp = selfPos(); if not mp then break end
    local foe, real = nearestFoe(mp)
    if not foe then break end
    gap = real
    if real >= A.StopAt then break end
    local dir = (mp - foe) * FLAT
    dir = (dir.Magnitude > 0.1) and dir.Unit or Vector3.new(0,0,1)
    -- Подмену позиции глушим только пока реально идём: tpProxy стёр бы уход.
    HUB.antiStepUntil = os.clock() + 0.05
    HUB.antiDir = dir
    -- ТИХО: без Move и Sprint на сервер, иначе замах читается как отмена
    steerToDir(dir, false, "anti", true)
    RunService.Heartbeat:Wait()
  end
  -- И выходим тоже тихо: обычный stopSteer шлёт Move(lastMoveDirection) и
  -- Sprint(состояние Shift). Это прилетело бы серверу ровно в конце замаха.
  stopSteerSoft("anti")
  HUB.antiStepUntil, HUB.antiDir = nil, nil
  if A.LegitFace and hp then faceBall(hp, 1/60, A.FaceRate, A.FaceSmooth) end
  HUB.antiSpeed, HUB.antiSpeedUntil = nil, nil

  local ep = selfPos()
  local walked = (startPos and ep) and ((ep - startPos) * FLAT).Magnitude or 0
  HUB.antiShot = ("retreat: gap %.1f -> %.1f, moved %.1f stds (%.0f ms)")
    :format(gap0, gap or gap0, walked, (os.clock()-t0)*1000)
  return walked, gap, "retreat"
end

function PBX.antiTest()
  local A = CFG.AntiDef
  local L = {}
  local function say(f, ...) L[#L+1] = ("  " .. f):format(...) end
  L[1] = "── ANTI DEFENSE TEST ──"
  say("mode %s | enabled %s | pre-shot %s | only with ball %s",
      tostring(A.Mode), tostring(A.Enabled), tostring(A.PreShot), tostring(A.OnlyBall))

  local me = selfPos()
  if not me then notify("anti test: no character"); return table.concat(L, "\n") end
  say("ball in our hands: %s", tostring(hasBall(chr())))
  say("in a match: %s", tostring(PBX.inMatch()))

  local n, near, nd, nG = 0, nil, nil, false
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      n += 1
      local q = posOf(sChild(c, "HumanoidRootPart"))
      if q then
        local d = ((q - me) * FLAT).Magnitude
        if not nd or d < nd then near, nd, nG = c, d, (sAttr(c, "HoldingG") == true) end
      end
    end
  end
  say("opponents seen: %d", n)
  if not near then
    say("VERDICT: nobody to step away from — isEnemy() found no one")
    notify("anti test: no opponents (see console/dump)")
    HUB.antiTest = table.concat(L, "\n"); return HUB.antiTest
  end
  local eff = nd / ((A.Stance and nG) and A.StanceWeight or 1)
  say("nearest %s at %.1f stds, holding G: %s, weighted %.1f (threshold %.1f)",
      near.Name, nd, tostring(nG), eff, A.React)
  if eff >= A.React then
    say("VERDICT: he is already far enough (%.1f >= %.1f), the step is skipped by design.", eff, A.React)
    say("         This is not a failure. Get within %.0f stds of an opponent to see it move.", A.React)
    HUB.antiTest = table.concat(L, "\n")
    notify(("anti test: nearest is %.1f stds away, nothing to dodge"):format(nd))
    return HUB.antiTest
  end
  say("steering channel: %s", tostring(HUB.pmSrc or "not installed"))

  if A.Mode ~= "Legit" then
    say("VERDICT: mode is %s — the step is done by position swap during the shot,", tostring(A.Mode))
    say("         so there is nothing to run outside a shot. Switch to Legit to test the legs.")
    HUB.antiTest = table.concat(L, "\n")
    notify(("anti test: mode %s has nothing to run outside a shot"):format(tostring(A.Mode)))
    return HUB.antiTest
  end
  local before = nd
  local walked, gap, mode = PBX.legitStep(HUB.gen, nearestHoop(me))
  say("ran: mode %s, walked %.1f stds, gap %.1f -> %.1f",
      tostring(mode), walked or 0, before, gap or before)
  if (walked or 0) < 0.3 then
    say("VERDICT: the legs did not move. Steering did not reach the game —")
    say("         check the line above: it must not say 'hookfunction failed'.")
  else
    say("VERDICT: works, gained %.1f stds", (gap or before) - before)
  end
  HUB.antiTest = table.concat(L, "\n")
  notify(("anti test: walked %.1f stds, gap %.1f -> %.1f")
    :format(walked or 0, before, gap or before))
  return HUB.antiTest
end

local function refineApproach(arc, me, t0, t1)
  local p0, v0 = arc.p0, arc.v0
  if not (p0 and v0) then return nil end
  local g = Vector3.new(0, -Workspace.Gravity, 0)
  local function distXZ(t)
    local p = p0 + v0*t + g*(0.5*t*t)
    return ((p - me) * FLAT).Magnitude, p
  end
  local a, b = math.max(t0, 0), t1
  for _ = 1, 24 do
    local m1 = a + (b - a)/3
    local m2 = b - (b - a)/3
    if distXZ(m1) <= distXZ(m2) then b = m2 else a = m1 end
  end
  local t = (a + b) * 0.5
  local d, p = distXZ(t)
  return t, d, p
end

function PBX.aeLoad()
  if PBX.AE.pkgs ~= nil or (os.clock() - PBX.AE.at) < 30 then return end
  PBX.AE.at = os.clock()
  pcall(function()
    local cfg = sChild(sChild(sChild(sChild(sChild(
      cloneref(game:GetService("ReplicatedStorage")), "Aero"), "Shared"), "Config"), "Game"), "Basketball")
    if cfg then PBX.AE.types = require(cfg) end
  end)
  pcall(function()
    local packs = sChild(sChild(sChild(sChild(sChild(sChild(
      cloneref(game:GetService("ReplicatedStorage")), "Aero"), "Shared"), "Config"), "Game"), "Shooting"), "Packages")
    if not packs then return end
    local t = {}
    for _, pk in ipairs(packs:GetChildren()) do
      local js = sChild(pk, "Jumpshot")
      if js then
        local ok, m = pcall(require, js)
        if ok and type(m) == "table" then

          t[tonumber(pk.Name)] = { arc = m.ArcEffect, rel = m.ReleaseHeight, n = pk.Name }
        end
      end
    end
    PBX.AE.pkgs = t
  end)
end

-- ИГРА СКЛАДЫВАЕТ ДВА ЧИСЛА, А МЫ ВОЗВРАЩАЛИ ОДНО.
-- Shoot_ModuleScript:84 (и Effect:82, Finisher:48) считают так:
--   эффект = (ArcEffect АНИМАЦИИ or 0) + (ArcEffect ТИПА БРОСКА or 1)
-- В конфиге игры это два разных диапазона: тип броска даёт 0.675..1.05
-- (Basketball_ModuleScript), а пакет джампшота — всего лишь ПОПРАВКУ
-- -0.10..+0.25. Наш код при имени вида Jumpshot<N> возвращал поправку как
-- итоговое значение: 0.125 вместо 0.125 + 0.9 = 1.025, ошибка в восемь раз.
-- И это была ПЕРВАЯ ветка, то есть срабатывала на каждом джампшоте.
-- Имя анимации тип броска не называет (Jumpshot1LBase — это просто пакет),
-- поэтому базу берём по дистанции из таблицы самой игры.
function PBX.arcEffOf(c, dist)
  PBX.aeLoad()
  local T = PBX.AE.types
  local function typeArc(key)
    local e = T and T[key]
    return (e and type(e.ArcEffect) == "number") and e.ArcEffect or nil
  end

  local anim = sAttr(c, "BaseAnimation")
  local base, baseSrc, mod, modSrc, rel = nil, nil, 0, nil, nil

  if type(anim) == "string" and T then
    -- Имя анимации, если оно прямо называет тип, важнее любых догадок.
    for _, key in ipairs({ "ContactLayup", "ClutchLayup", "ReverseLayup",
                           "DrivingLayup", "InsideHandLayup", "CloseShot",
                           "PostHook", "Floater",
                           "ThreePointFadeAway", "MidRangeFadeAway",
                           "ThreePointShot", "MidRangeShot" }) do
      if anim:find(key, 1, true) then
        base, baseSrc = typeArc(key), key
        if base then break end
      end
    end
  end

  if not base and T then
    -- Тип по дистанции, числа берём из таблицы игры, а не из головы.
    local line = CFG.S3 and CFG.S3.LineDist or 23.5
    local key = (dist and dist >= line) and "ThreePointShot"
             or ((dist and dist < 14) and "CloseShot" or "MidRangeShot")
    base, baseSrc = typeArc(key), key .. " by distance"
  end

  if type(anim) == "string" and PBX.AE.pkgs then
    local num = anim:match("^Jumpshot(%d+)")
    if num then
      local pk = PBX.AE.pkgs[tonumber(num)]
      if pk and type(pk.arc) == "number" then
        mod, modSrc, rel = pk.arc, tostring(pk.n), pk.rel
      end
    end
  end

  if base then
    HUB.aeSrc = ("%s %.3f%s"):format(tostring(baseSrc), base,
      modSrc and (" + package %s %+.3f"):format(modSrc, mod) or "")
    return math.clamp(base + mod, CFG.Grab.ArcEffMin, CFG.Grab.ArcEffMax), rel
  end

  local k = (dist and dist < 15) and "near" or ((dist and dist < 30) and "mid" or "far")
  local ae = (HUB.arcEffB and HUB.arcEffB[k]) or HUB.arcEff or CFG.Grab.ArcEffect
  HUB.aeSrc = ("learned %s (game config not readable)"):format(k)
  return math.clamp(ae, CFG.Grab.ArcEffMin, CFG.Grab.ArcEffMax), rel
end

local fsaCache, fsaAt = {}, 0
local function futureShotArc(c)
  if not c then return nil end
  local now0 = os.clock()
  if now0 - fsaAt > 0.03 then fsaCache = {}; fsaAt = now0 end
  local hit = fsaCache[c]
  if hit ~= nil then return hit or nil end
  local sst = sAttr(c, "ShotStartTime")
  local now = srvNow()
  if not (type(sst) == "number" and now) then fsaCache[c] = false; return nil end
  local tgt = goalPosOf(c) or hoopWeDefend()
  local rp = posOf(sChild(c, "HumanoidRootPart"))
  if not (tgt and rp) then fsaCache[c] = false; return nil end

  local _, relTmp = PBX.arcEffOf(c, 20)

  if type(relTmp) ~= "number" or relTmp < 2 or relTmp > 8 then
    relTmp = CFG.Grab.BallUp
  end
  local p0 = rp + Vector3.new(0, relTmp, 0)
  local dist = (tgt - p0).Magnitude
  local ae = select(1, PBX.arcEffOf(c, dist))
  local T = dist/85 + ae
  if T <= 0.05 then fsaCache[c] = false; return nil end
  local g = Vector3.new(0, -Workspace.Gravity, 0)
  local v0 = (tgt - p0 - g*(0.5*T*T)) / T
  local tRelease = math.max(CFG.Grab.ShootTime - (now - sst), 0)

  local arc = PBX.march(p0, v0, T * CFG.Grab.PreArcTail, CFG.Traj.PhysSamples, nil)

  local preHit = #arc
  for i, sp in ipairs(arc) do if sp.hit then preHit = i - 1; break end end
  local sd
  for i = 2, preHit do
    local sp = arc[i]
    if sp.p.Y < arc[i-1].p.Y and sp.p.Y >= tgt.Y - CFG.Traj.ScoreRad then
      local dd = ((sp.p - tgt) * FLAT).Magnitude
      if not sd or dd < sd then sd = dd end
    end
  end
  local out = { arc = arc, tRelease = tRelease, T = T, target = tgt, shooter = c,
                hits = (sd ~= nil and sd <= CFG.Traj.ScoreRad), scoreDist = sd }
  fsaCache[c] = out
  return out
end

function PBX.preCatchSpot()
  if not CFG.Grab.PreCatch then return nil end
  local me = selfPos(); if not me then return nil end

  local shooter, age
  for _, c in ipairs(charsList()) do
    local a = PBX.shotAge(c)
    if a and PBX.shotKind(c) ~= "rim" and (not age or a < age) then shooter, age = c, a end
  end
  if not shooter then return nil, "nobody shooting" end
  local f = futureShotArc(shooter)
  if not f then return nil, "no predicted arc" end
  if f.hits and CFG.Grab.SkipMakes then return nil, "predicted make" end

  local firstHit
  for i, sp in ipairs(f.arc) do if sp.hit then firstHit = i; break end end
  if not firstHit then return nil, "no rim contact predicted" end
  local reach, speed = JP.reachY(), math.max(ourSpeed(), 1)
  for i = firstHit + 1, #f.arc do
    local sp = f.arc[i]
    local dy = sp.p.Y - me.Y
    local run = ((sp.p - me) * FLAT).Magnitude

    if dy >= -2 and dy <= reach and run <= CFG.Grab.PreCatchMax then

      local need = math.max(run - CFG.Grab.CatchBody, 0) / speed
      if need <= f.tRelease + sp.t then
        return sp.p, ("rebound in %.0f ms"):format((f.tRelease + sp.t) * 1000)
      end
    end
  end
  return nil, "rebound point not reachable"
end

local function bestBlockSpot(arc, tMax, hoop)
  local ground = groundLevel()
  local me = selfPos()
  if not ground then ground = me and (me.Y) or nil end
  if not ground then return nil end
  hoop = hoop or hoopWeDefend()
  local limit = ground + JP.reachY()

  local closeShot = false
  if hoop and arc.p0 then
    closeShot = ((arc.p0 - hoop) * FLAT).Magnitude <= CFG.Grab.CloseShot
  end

  local floorY = ground + CFG.Grab.MinAbove
  if hoop and not closeShot then
    floorY = math.max(floorY, hoop.Y - CFG.Grab.RimDrop)
  end
  local tStop = tMax
  if hoop then
    local bi, bdh
    for i, sp in ipairs(arc) do
      local d = ((sp.p - hoop) * FLAT).Magnitude
      if not bdh or d < bdh then bi, bdh = i, d end
    end
    local tHoop = bi and arc[bi] and arc[bi].t
    if tHoop then
      tHoop += CFG.Grab.PastHoop
      tStop = tStop and math.min(tStop, tHoop) or tHoop
    end
  end
  local bp, bt, bd, bdy
  for _, sp in ipairs(arc) do
    if sp.t > 0 and (not tStop or sp.t <= tStop) and sp.p.Y <= limit
       and sp.p.Y >= floorY then
      local d = hoop and ((sp.p - hoop) * FLAT).Magnitude or 0
      if not bd or d < bd then bp, bt, bd, bdy = sp.p, sp.t, d, sp.p.Y - ground end
    end
  end
  if not bp then
    HUB.spotWhy = ("no reachable point in %.1f..%.1f before the hoop")
      :format(floorY - ground, JP.reachY())
    return nil
  end
  if bp and hoop and bd > CFG.Grab.RimZone then
    HUB.spotWhy = ("no reachable point near the hoop (best %.1f stds out)"):format(bd)
    return nil
  end
  if bp then
    HUB.spotWhy = ("spot %.1f stds from hoop, dy %+.1f, in %.0f ms")
      :format(bd or -1, bdy or 0, (bt or 0)*1000)
  end
  return bp, bt, bdy
end

track(RunService.Heartbeat:Connect(function(dt)
  if not (HUB.running and CFG.Grab.Enabled and CFG.Grab.FaceBall) then return end
  if PBX.ballIsOurs() then return end
  local me = selfPos(); if not me then return end
  local tPass, target = nil, nil

  if BALL.state == "flight" and HUB.arc and HUB.arc.arc
     and BALL.shooter and isEnemy(BALL.shooter) then
    local hi = pickInterceptPoint(HUB.arc, {
      skipOwn = CFG.Grab.SkipOwn, goalCheck = CFG.Grab.GoalCheck,
      rad = CFG.Grab.GoalRad, fitN = CFG.Grab.GuardFitN
    })
    if hi then
      local bp, bt = bestBlockSpot(HUB.arc.arc, nil, hoopWeDefend())
      if bp then
        tPass = bt
        target = defenseFaceTarget((ballTrueNow(BALL.pos, BALL.vel, BALL.stale)) or bp,
                                   BALL.shooter, hoopWeDefend())
      end
    end
  else
    local fpool, fn = foeSnap()
    for fi = 1, fn do
      local fe = fpool[fi]
      local c = fe.c
      if fe.ball then
        local act, cp = fe.act, fe.p
        if act == "Dunking" and cp then

          tPass, target = 0, cp
          break
        elseif act == "Shooting" and cp then
          local f = futureShotArc(c)
          if f then
            local bp, bt = bestBlockSpot(f.arc, nil, hoopWeDefend())
            if bp then
              tPass = (f.tRelease or 0) + bt
              target = cp + Vector3.new(0, CFG.Grab.BallUp, 0)
            end
          end
          break
        end
      end
    end
  end

  if not (tPass and target) then return end
  if tPass > JP.jumpLead(0) + CFG.Grab.FaceWindow then
    HUB.faceWhy = ("waiting, pass in %.2fs"):format(tPass)
    return
  end
  HUB.faceWhy = ("facing, pass in %.2fs"):format(tPass)
  faceBall(target, dt, CFG.Face.Rate, CFG.Face.Smooth)
end))

local function stanceFoe(me, maxD)
  local best, bd = nil, nil
  for _, c in ipairs(charsList()) do
    if isEnemy(c) then
      local p = posOf(sChild(c, "HumanoidRootPart"))
      if p then
        local d = ((p - me) * FLAT).Magnitude
        if d <= (maxD or 10) and (not bd or d < bd) then

          if sAttr(c, "HoldingG") == true or d <= SLIP.keepDist(c) then
            best, bd = c, d
          end
        end
      end
    end
  end
  return best, bd
end

track(RunService.Heartbeat:Connect(function(dt)
  local S = CFG.Move.Slip
  if not (HUB.running and S.Enabled) then return end
  if not hasBall(chr()) then return end
  local me = selfPos(); if not me then return end

  if S.Mode == "Feint" and S.LookFake then
    local mv = SLIP.juke.aim
    local raw = SLIP.juke.want
    if mv and raw then
      local cross = mv.X * raw.Z - mv.Z * raw.X
      local sgn = (cross >= 0) and 1 or -1
      local ang = math.rad(S.LookOff) * sgn
      local ca, sa = math.cos(ang), math.sin(ang)
      local lk = Vector3.new(mv.X*ca - mv.Z*sa, 0, mv.X*sa + mv.Z*ca)
      if lk.Magnitude > 1e-3 then
        faceBall(me + lk.Unit * 12, dt, S.LookRate, 1.0)
        HUB.slipFace = ("look %d deg off the run"):format(S.LookOff * sgn)
        return
      end
    end
  end
  local m = HUB.mov
  local dir = nil
  if m then
    local ok, d = pcall(RDR.MoveDirection, m)
    if ok and typeof(d) == "Vector3" and d.Magnitude > 0.1 then
      dir = (d * FLAT)
      if dir.Magnitude > 0.05 then dir = dir.Unit else dir = nil end
    end
  end
  if not dir then return end

  local foe = stanceFoe(me, 10)
  if not foe then
    local f2, d2, r2 = SLIP.slipBlocker(me, dir)
    if f2 and r2 and d2 and d2 <= r2 * 1.25 then foe = f2 end
  end
  if not foe then return end
  local fp = posOf(sChild(foe, "HumanoidRootPart")); if not fp then return end
  local to = ((fp - me) * FLAT); if to.Magnitude < 0.1 then return end
  to = to.Unit
  local right = Vector3.new(-to.Z, 0, to.X)
  local sign = (right:Dot(dir) >= 0) and 1 or -1
  local a = math.rad(S.LookDeg) * sign
  local ca, sa = math.cos(a), math.sin(a)
  local look = Vector3.new(to.X*ca - to.Z*sa, 0, to.X*sa + to.Z*ca)
  faceBall(me + look * 10, dt, CFG.Face.Rate, CFG.Face.Smooth)
end))

local G2_lastSteal = 0

local function threatBudget(carrier)

  if BALL.state == "flight" and HUB.arc and HUB.arc.arc then
    local hi = pickInterceptPoint(HUB.arc, {
      skipOwn = true, goalCheck = CFG.Grab.GoalCheck, rad = CFG.Grab.GoalRad,
      fitN = CFG.Grab.GuardFitN
    })
    if not hi then return nil, nil end
    local bp, bt = bestBlockSpot(HUB.arc.arc, nil, hoopWeDefend())
    if bp then return bt, bp end
    local sp = HUB.arc.arc[hi]
    if sp then return sp.t, sp.p end
    return nil, nil
  end

  if carrier and PBX.shotKind(carrier) == "projectile" then
    local f = futureShotArc(carrier)
    if f then
      local bp, bt = bestBlockSpot(f.arc, nil, hoopWeDefend())
      if bp then return (f.tRelease or 0) + bt, bp end
      return f.tRelease, nil
    end
  end
  return nil, nil
end

local function enemyCarrier()
  local hp = hoopWeDefend()
  local best, bd = nil, nil
  for _, c in ipairs(charsList()) do
    if isEnemy(c) and hasBall(c) then
      local p = posOf(sChild(c, "HumanoidRootPart"))
      if p then
        local d = hp and ((p - hp) * FLAT).Magnitude or 0
        if not bd or d < bd then best, bd = c, d end
      end
    end
  end
  return best, bd
end

local function rimCoverSpot(hp, from)
  local dir = (from and ((from - hp) * FLAT) or Vector3.new(0,0,1))
  if dir.Magnitude < 0.1 then dir = Vector3.new(0,0,1) end
  dir = dir.Unit
  local og = ourGoalPos()
  if og then
    local inCourt = ((og - hp) * FLAT)
    if inCourt.Magnitude > 0.1 then
      inCourt = inCourt.Unit
      local d = dir:Dot(inCourt)
      if d < 0.15 then

        dir = (dir - inCourt * d + inCourt * 0.35)
        if dir.Magnitude < 0.1 then dir = inCourt else dir = dir.Unit end
      end
    end
  end
  return hp + dir * CFG.Move2.RimStand
end

track(RunService.Heartbeat:Connect(function(dt)
  local M2 = CFG.Move2

  if not (M2.Enabled and CFG.Grab.Enabled and HUB.running) then

    if HUB.autoStance and R.HoldG then
      HUB.autoStance = false
      HUB.bypass = true
      pcall(Mt.FireServer, R.HoldG, { HoldingG = false })
      HUB.bypass = false
    end
    stopSteer("automove"); HUB.autoHeld = false; return
  end
  if CFG.Grab.OnlyInMatch and not PBX.inMatch() then

    if HUB.autoStance and R.HoldG then
      HUB.autoStance = false
      HUB.bypass = true
      pcall(Mt.FireServer, R.HoldG, { HoldingG = false })
      HUB.bypass = false
    end
    HUB.autoWhy = "not in a match"; stopSteer("automove"); HUB.autoHeld = false; return
  end
  if PBX.ballIsOurs() then
    HUB.autoWhy = "the ball is ours"; stopSteer("automove"); return
  end

  if HUB.moveOwner and HUB.moveOwner ~= "automove" then return end
  local me = selfPos(); if not me then return end
  local hp = hoopWeDefend(); if not hp then HUB.autoWhy = "our hoop unknown"; return end

  local carrier, carrierToHoop = enemyCarrier()
  if carrier and M2.HoopRad > 0 and (carrierToHoop or 1e9) > M2.HoopRad then
    carrier = nil
  end
  local budget, ballPt = threatBudget(carrier)

  local speed = ourSpeed()

  local function runTime(pt)
    return (((pt - me) * FLAT).Magnitude / math.max(speed, 1)) * M2.Margin
  end
  local function canMake(pt)
    local t = runTime(pt)
    if M2.MaxRun > 0 and t > M2.MaxRun then return false end
    if not budget then return true end
    return t <= budget
  end

  local spot, why = nil, nil
  if ballPt and canMake(ballPt) then
    spot, why = ballPt, ("to the ball, %.2fs"):format(budget or -1)
  end

  local carrierShooting = carrier and PBX.isShot(carrier) or false
  if not spot and carrier and (carrierShooting or CFG.Defense.Enabled) then
    local cp = posOf(sChild(carrier, "HumanoidRootPart"))
    if cp then
      local v = charVel(carrier) * CFG.Grab.LeadTime
      local ahead = cp + Vector3.new(v.X, 0, v.Z)
      local toHoop = (hp - ahead) * FLAT
      local guard = (toHoop.Magnitude > 0.1)
                    and (ahead + toHoop.Unit * M2.Standoff) or ahead
      if canMake(guard) then
        spot, why = guard, carrierShooting and "onto the shooter" or "onto the carrier"
      else
        why = ("cannot reach carrier in %.2fs"):format(budget or -1)
      end
    end
  end

  local threat = (carrier ~= nil) or (ballPt ~= nil)
  if not spot then
    if not threat then
      HUB.autoWhy = "no threat, you have control"
      HUB.autoHeld = false
      stopSteerSoft("automove")
      return
    end
    local from = ballPt or (carrier and posOf(sChild(carrier, "HumanoidRootPart"))) or BALL.pos
    local rim = rimCoverSpot(hp, from)

    if M2.MaxRun > 0 and runTime(rim) > M2.MaxRun then
      HUB.autoWhy = ("too far to help (%.2fs), you have control"):format(runTime(rim))
      stopSteerSoft("automove")
      return
    end
    spot = rim
    why = (why and (why .. " -> rim")) or "holding the rim"
  end
  HUB.autoWhy = why

  local d = ((spot - me) * FLAT).Magnitude
  if HUB.autoHeld then
    local moved = HUB.autoSpot
                  and ((spot - HUB.autoSpot) * FLAT).Magnitude or 1e9
    if d < M2.HoldTol and moved < M2.HoldTol then
      HUB.autoWhy = (why or "holding") .. " (holding)"
      stopSteerSoft("automove")
      return
    end
    HUB.autoHeld = false
  end
  if d < 1.5 then
    HUB.autoHeld, HUB.autoSpot = true, spot
    stopSteerSoft("automove")
  else
    local dir = ((spot - me) * FLAT).Unit
    steerToDir(dir, M2.Sprint and (d > 6) or false, "automove")
  end

  if carrier then
    local cp = posOf(sChild(carrier, "HumanoidRootPart"))
    local near = cp and ((cp - me) * FLAT).Magnitude or 1e9

    if R.HoldG then
      local stanceOn = M2.Stance and CFG.Defense.Enabled
      local want = stanceOn and (near <= M2.StanceRad) or false
      if want ~= (HUB.autoStance == true) then
        HUB.autoStance = want
        HUB.bypass = true
        pcall(Mt.FireServer, R.HoldG, { HoldingG = want })
        HUB.bypass = false
      end
    end
    if M2.Steal and CFG.Defense.Enabled and R.Steal and near <= M2.StealRad
       and os.clock() - G2_lastSteal >= M2.StealCD then
      G2_lastSteal = os.clock()
      HUB.bypass = true
      pcall(Mt.FireServer, R.Steal)
      HUB.bypass = false
    end

    local fm = CFG.Face.Mode
    if fm ~= "Off" then
      local tgt = cp
      if fm == "Ball" and BALL.pos then
        tgt = (ballTrueNow(BALL.pos, BALL.vel, BALL.stale)) or BALL.pos
      end
      if tgt then faceBall(tgt, dt, CFG.Face.Rate, CFG.Face.Smooth) end
    end
  elseif HUB.autoStance then
    HUB.autoStance = false
    if R.HoldG then
      HUB.bypass = true
      pcall(Mt.FireServer, R.HoldG, { HoldingG = false })
      HUB.bypass = false
    end
  end
end))

local function guardOnArc(arc, me, tMax, tOffset, label, dt, ballPart)

  local step = (arc[2] and arc[1] and (arc[2].t - arc[1].t))
               or (CFG.Traj.PhysDuration / CFG.Traj.PhysSamples)
  if step <= 0 then step = CFG.Traj.PhysDuration / CFG.Traj.PhysSamples end
  local bi, bd, biAny, bdAny = nil, nil, nil, nil
  for i, sp in ipairs(arc) do
    if sp.t > tMax then break end
    if sp.t > 0 then
      local dxz = ((sp.p - me) * FLAT).Magnitude
      local dyS = sp.p.Y - me.Y
      if not bdAny or dxz < bdAny then biAny, bdAny = i, dxz end
      if dyS >= -2 and dyS <= JP.reachY() then
        if not bd or dxz < bd then bi, bd = i, dxz end
      end
    end
  end
  if not bi then bi, bd = biAny, bdAny end
  if not bi then HUB.grabWhy = "arc empty"; return false end
  local lo = math.max((arc[bi].t or 0) - step, 0)
  local hiT = math.min((arc[bi].t or 0) + step, tMax)
  if hiT <= lo then hiT = math.min(lo + step, tMax) end
  local tc, dxz, pc = refineApproach(arc, me, lo, hiT)
  if not tc then tc, dxz, pc = arc[bi].t, bd, arc[bi].p end
  if tc <= 0 then HUB.grabWhy = "pass already behind us"; return false end
  if dxz > CFG.Grab.ReachXZ then
    HUB.grabWhy = ("%s: ball passes %.1f stds away, reach %.1f")
      :format(label, dxz, CFG.Grab.ReachXZ)
    PBX.gs("ball passes too far sideways", dxz)
    return false
  end
  local dy = pc.Y - me.Y
  if (dy < -2 or dy > JP.reachY()) and bd then
    local sp = arc[bi]
    local dyS = sp.p.Y - me.Y
    if dyS >= -2 and dyS <= JP.reachY() then tc, dxz, pc, dy = sp.t, bd, sp.p, dyS end
  end
  if dy < -2 or dy > JP.reachY() then
    HUB.grabWhy = ("%s: ball %+.1f stds up, we reach %.1f"):format(label, dy, JP.reachY())
    PBX.gs("ball above our reach", dy)
    return false
  end
  local tTotal = tc + (tOffset or 0)
  local lead = JP.jumpLead(dy)
  HUB.grabWhy = ("%s: %.1f stds, dy %+.1f, in %.0f ms, jump at %.0f ms")
    :format(label, dxz, dy, tTotal*1000, lead*1000)
  if tTotal <= lead then
    PBX.gs("jumped", dy)
    local ball = ballPart and (ballTrueNow(posOf(ballPart), BALL.vel, BALL.stale)) or pc
    doJump(("rim guard (%s): %.1f stds, dy %.1f, in %.0f ms (lead %.0f ms)")
           :format(label, dxz, dy, tTotal*1000, lead*1000), ball, dt, pc, tTotal, dy)
    return true
  end
  faceBall(defenseFaceTarget(pc, BALL.shooter, hoopWeDefend()), dt)
  return true
end

local function rimGuardTick(dt)
  if not (CFG.Grab.Enabled and CFG.Grab.RimGuard) then return false end
  if CFG.Grab.OnlyInMatch and not PBX.inMatch() then
    HUB.grabWhy = "not in a match"; return false
  end
  local me = selfPos(); if not me then return false end
  if PBX.ballIsOurs() then PBX.gs("we hold the ball"); return false end
  PBX.gs("ticks")

  local info = HUB.arc
  if CFG.Grab.PreShot and not (info and info.arc) then
    for _, c in ipairs(charsList()) do

      if isEnemy(c) and PBX.shotKind(c) == "projectile" and hasBall(c) then
        local hp = hoopWeDefend()
        local cp = posOf(sChild(c, "HumanoidRootPart"))
        local mine = true
        if CFG.Grab.GoalCheck and hp then
          local g2 = goalPosOf(c)
          mine = (not g2) or ((g2 - hp).Magnitude < 12)
        end
        if mine and cp then
          local f = futureShotArc(c)

          local elapsedShot = f and (CFG.Grab.ShootTime - (f.tRelease or 0)) or 0
          if f and elapsedShot >= CFG.Grab.MinCommit then
            PBX.gs("pre-shot arc built")
            if guardOnArc(f.arc, me, CFG.Grab.LookAhead, f.tRelease,
                          "pre-shot", dt, nil) then
              PBX.gs("pre-shot acted"); return true
            end
          end
        end
      end
    end
  end

  if not (info and info.arc) then PBX.gs("no ball in flight"); return false end
  PBX.gs("ball in flight")

  local hi, _, _, why = pickInterceptPoint(info, {
    skipOwn   = CFG.Grab.SkipOwn,
    goalCheck = CFG.Grab.GoalCheck,
    rad       = CFG.Grab.GoalRad,
    fitN      = CFG.Grab.GuardFitN
  })
  if not hi then
    HUB.grabWhy = why

    PBX.gs("gate: " .. tostring(why):gsub(":.*", ""):sub(1, 40), HUB.lastHoopDist)
    return false
  end
  PBX.gs("gate passed")

  local arc = info.arc

  local tHoop = (arc[hi] and arc[hi].t or CFG.Grab.LookAhead) + CFG.Grab.PastHoop

  local tMax = math.max(math.min(CFG.Grab.LookAhead, tHoop), math.min(tHoop, CFG.Traj.PhysDuration))
  return guardOnArc(arc, me, tMax, 0, "in flight", dt, info.ball)
end

track(RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(PBX.guarded("intercept", function(dt)
  if not (CFG.Grab.Enabled and HUB.running) then stopSteer("grab"); return end

  if CFG.Grab.OnlyInMatch and not PBX.inMatch() then
    HUB.blockWhy = "not in a match"; stopSteer("grab"); return
  end

  if PBX.ballIsOurs() then
    HUB.blockWhy = "the ball is ours"; stopSteer("grab"); return
  end
  -- ПОКА CONTEST SHOOTER ДЕРЖИТ ПОДМЕНУ ПОЗИЦИИ — ПЕРЕХВАТ МОЛЧИТ.
  -- Он считает всё от нашей позиции, а во время телепорта она подменена: тик
  -- видит «мяч вдруг рядом», начинает вести и прыгать, и одновременно с этим
  -- blatantHold каждый кадр возвращает CFrame обратно. Две системы дерутся за
  -- одно тело. Гейта здесь не было вообще.
  -- читаем HUB, а НЕ BL: таблица BL объявлена НИЖЕ этого тика, прямая ссылка
  -- отсюда попала бы в глобал nil и гейт не работал бы никогда
  if HUB.blatantHolding then
    HUB.blockWhy = "contest shooter is holding position"
    stopSteer("grab"); return
  end
  local me = selfPos(); if not me then return end

  if rimGuardTick(dt) then return end

  local camping = false
  if CFG.Grab.RimGuard and CFG.Grab.CampRad > 0 then
    local hp = hoopWeDefend()
    if hp and ((me - hp) * FLAT).Magnitude <= CFG.Grab.CampRad then
      camping = true
    end
  end

  local sawRim = false
  do
    local hp = hoopWeDefend()

    if hp then

      local fpool, fn = foeSnap()
      for fi = 1, fn do
        local fe = fpool[fi]
        local c = fe.c
        local k = PBX.shotKind(c)
        if (k == "rim" or k == "windup") and fe.ball then
          local cp = fe.p
          if cp then
            local toHoop = ((cp - hp) * FLAT).Magnitude
            local toUs   = ((cp - me) * FLAT).Magnitude
            if toHoop <= CFG.Grab.RimAttackRad then
              sawRim = true
              if toUs <= CFG.Grab.BlockRange then
                if (os.clock() - (HUB.lastRimAtk or 0)) >= CFG.Grab.RimAttackCD
                   and (os.clock() - (HUB.lastJump or 0)) >= CFG.Grab.JumpCD then
                  HUB.lastRimAtk = os.clock()
                  HUB.blockWhy = ("rim attack: %s, %.1f from hoop, %.1f from us")
                    :format(tostring(sAttr(c, "Action")), toHoop, toUs)
                  PBX.gs("rim attack jump", toUs)
                  doJump(HUB.blockWhy, cp, dt, cp, 0, (cp.Y - me.Y) + CFG.Grab.BallUp)
                  return
                end

                faceBall(cp, dt)
                return
              else

                steerTo(cp, "grab")
                faceBall(cp, dt)
                HUB.blockWhy = ("rim attack: %s at %.1f from hoop, closing %.1f")
                  :format(tostring(sAttr(c, "Action")), toHoop, toUs)
                PBX.gs("rim attack closing", toUs)
                return
              end
            end
          end
        end
      end

      -- МЯЧ ДОЛЖЕН БЫТЬ СВОБОДЕН.
      -- Ветка не смотрела на владельца вообще: если соперник ведёт мяч у
      -- кольца, BALL.pos стоит в его руках, и мы бежали прямо на него. В
      -- статистике это 14629 срабатываний "rim catch closing" — самая частая
      -- активность тика. Взять такой мяч нельзя, гнаться незачем.
      -- И матч должен ИДТИ. До розыгрыша мяч лежит на стойке или в руках у
      -- судьи: взять его нельзя, а тик всё равно вёл нас к нему.
      local loose = (BALL.holder == nil) and not PBX.ballIsOurs()
                    and ((not CFG.Grab.OnlyInMatch) or PBX.matchLive())
      if CFG.Grab.RimCatch and BALL.pos and loose then
        local bp = (ballTrueNow(BALL.pos, BALL.vel, BALL.stale)) or BALL.pos
        local bH = ((bp - hp) * FLAT).Magnitude
        if bH <= CFG.Grab.RimCatchRad then
          local bU  = (bp - me).Magnitude
          local dyB = bp.Y - me.Y
          if bU <= CFG.Grab.RimCatchJump and dyB >= -2 and dyB <= JP.reachY() then
            if (os.clock() - (HUB.lastJump or 0)) >= CFG.Grab.JumpCD then
              HUB.blockWhy = ("rim catch: ball %.1f from hoop, %.1f from us, dy %+.1f")
                :format(bH, bU, dyB)
              PBX.gs("rim catch jump", bU)
              doJump(HUB.blockWhy, bp, dt, bp, 0, dyB)
              return
            end
          elseif bU <= CFG.Grab.RimCatchRun then

            local falling = BALL.vel and BALL.vel.Y < -1
            if dyB <= JP.reachY() or falling then
              -- ПРЫГАЕМ ЗАРАНЕЕ, А НЕ ПО ФАКТУ ПРИБЫТИЯ.
              -- Прыжок отсюда уходил с tPred = 0: в журнале это шесть записей
              -- из десяти с lead = 0, то есть решение принималось, когда мяч
              -- уже на месте. При пинге в 300 мс это гарантированное опоздание.
              -- Считаем, когда мяч ВОЙДЁТ в зону хвата, и прыгаем на величину
              -- упреждения раньше.
              if BALL.vel and (os.clock() - (HUB.lastJump or 0)) >= CFG.Grab.JumpCD then
                -- СКОРОСТЬ СБЛИЖЕНИЯ, А НЕ ОДНА ЛИШЬ СКОРОСТЬ МЯЧА.
                -- Первая версия делила ТРЁХМЕРНУЮ дистанцию на ГОРИЗОНТАЛЬНУЮ
                -- скорость мяча и не учитывала, что мы к нему сами бежим. В
                -- журнале это прыжки с упреждением 470..637 мс, у которых мяч
                -- приходил на полсекунды позже (arrErr от -461 до -557): мы
                -- взлетали и успевали приземлиться до его прилёта. Считаем по
                -- горизонтали и складываем обе скорости.
                local toB = (bp - me) * FLAT
                if toB.Magnitude > 0.1 then
                  local u = toB.Unit
                  local ballIn = -((BALL.vel * FLAT):Dot(u))
                  local myV = charVel(chr())
                  local meIn = (typeof(myV) == "Vector3") and ((myV * FLAT):Dot(u)) or 0
                  local closing = ballIn + meIn
                  if closing > 1 then
                    local tIn  = (toB.Magnitude - CFG.Grab.RimCatchJump) / closing
                    local lead = JP.jumpLead(dyB)
                    if tIn > 0 and tIn <= lead then
                      HUB.blockWhy = ("rim catch: jumping %.0f ms early, ball in %.0f ms")
                        :format(lead*1000, tIn*1000)
                      PBX.gs("rim catch jump early", tIn)
                      doJump(HUB.blockWhy, bp, dt, bp, tIn, dyB)
                      return
                    end
                  end
                end
              end
              steerTo(bp, "grab")
              faceBall(bp, dt)
              HUB.blockWhy = ("rim catch: closing on ball %.1f from hoop"):format(bH)
              PBX.gs("rim catch closing", bU)
              return
            end
            PBX.gs("ball parked above reach, not chasing", dyB - JP.reachY())
          end
        end
      end
    end
  end

  local sawShooter = false
  local spool, sn = foeSnap()
  for si = 1, sn do
    local se = spool[si]
    local c = se.c
    if PBX.shotKind(c) == "projectile" and se.ball then
      local cp = se.p

      local nearHoop = true
      if CFG.Grab.HoopRad > 0 and cp then
        local hp = hoopWeDefend()
        if hp then
          nearHoop = ((cp - hp) * FLAT).Magnitude <= CFG.Grab.HoopRad
        end
      end
      if not nearHoop then
        dbg("block", ("shooter too far from our hoop (> %.0f), skipping")
          :format(CFG.Grab.HoopRad))
        cp = nil
      end
      sawShooter = sawShooter or (cp ~= nil)
      local inRange = cp and ((cp - me) * FLAT).Magnitude <= CFG.Grab.BlockRange

      local onLine, facing = false, false
      if inRange and CFG.Grab.UseCones then
        local hoop = defendGoalPos(c)
        if hoop then
          local toHoop = (hoop - cp) * FLAT
          local toUs   = (me   - cp) * FLAT
          if toHoop.Magnitude > 0.1 and toUs.Magnitude > 0.1 then
            onLine = toHoop.Unit:Dot(toUs.Unit) >= CFG.Grab.BlockCone
          end
        end
        local pc = proxyPart()
        local okc, cf = false, nil
        if pc then okc, cf = pcall(RDR.CFrame, pc) end
        if okc and cf then
          local toHim = (cp - me) * FLAT
          if toHim.Magnitude > 0.1 then
            facing = cf.LookVector:Dot(toHim.Unit) >= CFG.Grab.FaceCone
          end
        end
      end

      if cp then
        if not HUB.shootAt[c] then HUB.shootAt[c] = os.clock() end
      else
        HUB.shootAt[c] = nil
      end

      local untilRelease
      if cp then

        local elapsed, tsrc = nil, nil
        local sst = sAttr(c, "ShotStartTime")
        local now = srvNow()
        if type(sst) == "number" and now then
          elapsed, tsrc = now - sst, "server"
        elseif HUB.shootAt[c] then
          elapsed, tsrc = os.clock() - HUB.shootAt[c], "local"
        end
        HUB.theirMeter = (function()
          local mv = sAttr(c, "meterOffset")
          if typeof(mv)=="Vector2" then
            local ax,ay = math.abs(mv.X), math.abs(mv.Y); return (ay>ax) and ay or ax
          elseif type(mv)=="number" then return math.abs(mv) end
          return nil
        end)()
        untilRelease = elapsed and (CFG.Grab.ShootTime - elapsed) or nil
        if untilRelease then

          local bp = posOf(sChild(c, "HumanoidRootPart"))
          local dy = CFG.Grab.BallUp + ((bp and bp.Y or me.Y) - me.Y)
          local lead = JP.jumpLead(dy)

          local tR = math.max(untilRelease, 0)

          local myV = charVel(chr())
          if typeof(myV) ~= "Vector3" then myV = Vector3.new() end
          local dirNow = HUB.moveWorld
          if typeof(dirNow) == "Vector3" and dirNow.Magnitude > 0.1 then
            myV = dirNow.Unit * ourSpeed()
          end
          local meAt  = me + Vector3.new(myV.X, 0, myV.Z) * tR
          local hisV  = charVel(c) * tR
          local himAt = cp + Vector3.new(hisV.X, 0, hisV.Z)
          local distNow = ((cp - me) * FLAT).Magnitude

          local distAt = math.min(distNow,
                                  ((himAt - meAt) * FLAT).Magnitude)
          local reach  = distAt <= CFG.Grab.BlockRange
          HUB.blockWhy = ("%s: shooting %.0f ms, release in %.0f ms, lead %.0f ms (lag %s), dist %.1f/%.1f")
            :format(tostring(tsrc), (elapsed or 0)*1000, untilRelease*1000, lead*1000,
                    HUB.jumpLag and ("%.0f ms"):format(HUB.jumpLag*1000) or "estimate",
                    distAt, distNow)
          local conesOk = (not CFG.Grab.UseCones) or (not inRange) or (onLine and facing)

          local committed = (elapsed or 0) >= CFG.Grab.MinCommit
          if untilRelease <= lead and reach and conesOk and committed then

            doJump(("release block (%s, release %.0f ms, dist %.1f)")
                   :format(tostring(tsrc), untilRelease*1000, distAt), cp, dt)
            return
          end

          if inRange then
            stopSteerSoft("grab")
            faceBall(cp, dt)
            return
          end
        elseif inRange then

          stopSteerSoft("grab")
          faceBall(cp, dt)
          return
        end
      end
      if cp and camping then

        stopSteerSoft("grab")
        faceBall(cp, dt)
        return
      elseif cp then

        local hoop = defendGoalPos(c) or hoopWeDefend()
        local vlead = charVel(c) * CFG.Grab.LeadTime
        local ahead = cp + Vector3.new(vlead.X, 0, vlead.Z)
        local spot = ahead
        if hoop then
          local toHoop = (hoop - ahead) * FLAT

          if toHoop.Magnitude > 0.1 then
            spot = ahead + toHoop.Unit * CFG.Grab.BlockStandoff
          end
        end

        if untilRelease then
          local dRun = ((spot - me) * FLAT).Magnitude
          local tRun = dRun / math.max(ourSpeed(), 1)
          if tRun > untilRelease + CFG.Grab.ChaseSlack then
            HUB.blockWhy = ("no chase: %.1f stds needs %.2fs, release in %.2fs")
              :format(dRun, tRun, untilRelease)
            stopSteerSoft("grab")
            return
          end
        end
        steerTo(spot, "grab")
        faceBall(ahead, dt)
        return
      end
    end
  end

  if CFG.Grab.Enabled and not sawShooter and not sawRim then
    table.clear(HUB.shootAt)
    HUB.blockWhy = "no enemy is shooting"
    dbg("block","no enemy shooting (needs Action=Shooting and the ball)")
  end

  local info = HUB.arc
  if CFG.Grab.Anticipate and (not info) then
    local shooting = nil
    local wpool, wn = foeSnap()
    for wi = 1, wn do
      local c = wpool[wi].c
      if wpool[wi].ball and PBX.isShot(c) then
        sawShooter = true shooting = c break
      end
    end
    if shooting then
      local gp = defendGoalPos(shooting)

      if gp and CFG.Grab.HoopRad > 0 then
        local sp0 = posOf(sChild(shooting, "HumanoidRootPart"))
        local hp = hoopWeDefend()
        if sp0 and hp and ((sp0 - hp) * FLAT).Magnitude > CFG.Grab.HoopRad then
          gp = nil
        end
      end
      if gp then

        local sp = posOf(sChild(shooting, "HumanoidRootPart"))
        if sp then
          local vl = charVel(shooting) * CFG.Grab.LeadTime
          sp = sp + Vector3.new(vl.X, 0, vl.Z)
        end
        local dir = sp and ((sp - gp) * FLAT) or Vector3.new(0,0,1)
        if dir.Magnitude < 0.1 then dir = Vector3.new(0,0,1) end

        local standoff = CFG.Grab.RimStandoff
        local f = futureShotArc(shooting)
        if f and f.arc then

          local gl = groundLevel() or (me and me.Y) or nil
          local limit = gl and (gl + JP.reachY()) or nil
          local best, reachable = nil, false
          if limit then

            local apexI = 1
            for i = 2, #f.arc do
              if f.arc[i].p.Y > f.arc[apexI].p.Y then apexI = i end
            end
            for i = apexI, #f.arc do
              if f.arc[i].p.Y <= limit then
                best = ((f.arc[i].p - gp) * FLAT).Magnitude
                reachable = true
                break
              end
            end
          end
          if reachable and best then
            standoff = math.clamp(best, CFG.Grab.RimStandoffMin, CFG.Grab.RimStandoffMax)
            HUB.blockWhy = ("rim cover %.1f stds out (arc, %s)")
              :format(standoff, tostring(HUB.aeSrc))
          elseif limit then

            HUB.blockWhy = "shot stays above our reach all the way to the rim"
            stopSteerSoft("grab")
            return
          end

        end
        local spot = gp + dir.Unit * standoff
        steerTo(spot, "grab")
        local d = ((spot - me) * FLAT).Magnitude
        if d < 2 then stopSteerSoft("grab") end
        return
      end
    end
    stopSteer("grab"); return
  end

  if not (info and info.arc) then
    if CFG.Grab.Catch then
      local spot, why = PBX.preCatchSpot()
      if spot then
        steerTo(spot, "grab")
        faceBall(spot, dt, CFG.Grab.CatchFaceRate)
        PBX.gs("moving to the rebound early")
        HUB.grabWhy = "pre-catch: " .. tostring(why)
        return
      end
      HUB.grabWhy = "pre-catch: " .. tostring(why or "no ball in flight")
    end
    stopSteer("grab"); return
  end
  if not CFG.Grab.Catch then stopSteer("grab"); return end
  if BALL.holder then
    stopSteer("grab"); PBX.gs("ball is held"); return
  end
  if (info.fitN or 0) < CFG.Grab.CatchFitN then
    stopSteer("grab"); PBX.gs("fit not ready"); return
  end

  if info.hits and CFG.Grab.SkipMakes then
    stopSteer("grab")
    PBX.gs("shot is going in, waiting for the inbound", HUB.scoreDist)
    return
  end

  local rcv = PBX.passTo(info.ball)
  if rcv and rcv ~= chr() then
    stopSteer("grab")
    PBX.gs(isEnemy(rcv) and "pass to an opponent (addressed, not catchable)"
                        or "pass to a teammate")
    return
  end

  local speed  = math.max(ourSpeed(), 1)
  local reach  = JP.reachY()
  local pick, pickT, pickDy, pickRun
  local lowP, lowT, lowDy, lowRun
  local hiP, hiT, hiDy, hiRun
  local nearMiss, nearMissBy

  for _, sp in ipairs(info.arc) do
    if sp.t > CFG.Grab.CatchAhead then break end
    if sp.t > 0.02 then
      local dy  = sp.p.Y - me.Y
      if dy >= -2 and dy <= reach then
        local run = ((sp.p - me) * FLAT).Magnitude

        local eff = math.max(run - CFG.Grab.CatchBody, 0)

        local need = eff / speed
        if dy > CFG.Grab.ArmReach then
          -- ПОДЪЁМ СТОИТ НЕ ТОЛЬКО ПОЛЁТА ТЕЛА, НО И ЛАГА ПРЫЖКА.
          -- Прыжок уходит ремоутом на сервер и возвращается: замеренный лаг
          -- в дампах 0.40..0.51 с. Без него расчёт говорит "успеваем", мы
          -- добегаем и прыгаем уже мимо — ровно те промахи, где нужен был
          -- подъём на 1.1..1.4 студа.
          need = need + JP.bodyRise(dy)
                      + (HUB.jumpLag or (CFG.Grab.JumpLagFallback * (dataPing() or 0.1)))
        end
        if need <= sp.t then

          if dy <= CFG.Grab.ArmReach then
            if not lowP then lowP, lowT, lowDy, lowRun = sp.p, sp.t, dy, run end
            break
          elseif not hiP then
            hiP, hiT, hiDy, hiRun = sp.p, sp.t, dy, run
          end
        elseif not nearMiss or (need - sp.t) < nearMissBy then
          nearMiss, nearMissBy = sp, need - sp.t
        end
      end
    end
  end

  if lowP and (not hiP or lowT - hiT <= CFG.Grab.GroundWait) then
    pick, pickT, pickDy, pickRun = lowP, lowT, lowDy, lowRun
    if hiP then PBX.gs("taking it off the floor instead of jumping", lowT - hiT) end
  elseif hiP then
    pick, pickT, pickDy, pickRun = hiP, hiT, hiDy, hiRun
  end

  if not pick then

    local chaseRun = nearMiss and nearMiss.p
      and ((nearMiss.p - me) * FLAT).Magnitude or nil
    local tooFar = chaseRun and CFG.Grab.CatchMaxRun > 0
                   and chaseRun > CFG.Grab.CatchMaxRun
    if nearMiss and nearMissBy and nearMissBy <= CFG.Grab.CatchChase and not tooFar then
      steerTo(nearMiss.p, "grab")
      if BALL.pos then faceBall(nearMiss.p, dt, CFG.Grab.CatchFaceRate) end
      PBX.gs("closing on ball", nearMissBy)
      HUB.grabWhy = ("closing, short by %.0f ms"):format(nearMissBy * 1000)
    else
      stopSteer("grab")
      if tooFar then
        PBX.gs("too far to chase, leaving you alone", chaseRun)
        HUB.grabWhy = ("too far to chase (%.0f stds), not steering"):format(chaseRun)
      else
        PBX.gs("no reachable catch point", nearMissBy)
        HUB.grabWhy = "ball never comes within reach in time"
      end
    end
    return
  end

  HUB.grabWhy = ("catch in %.0f ms, %.1f stds away, dy %+.1f")
    :format(pickT * 1000, pickRun, pickDy)

  -- ЦЕЛЬ ХОДЬБЫ СМЕЩАЕМ ВПЕРЁД ПО ДУГЕ, А ЦЕЛЬ ВЗГЛЯДА ОСТАВЛЯЕМ НА МЯЧЕ.
  -- Смотрим туда, где мяч будет в момент хвата, но ногами идём чуть дальше:
  -- если хват не состоится, мяч пойдёт мимо нас вперёд, а мы уже там.
  local goTo = pick
  if CFG.Grab.CatchLead > 0 and info and info.arc then
    local arc = info.arc
    local iAt
    for i2, sp in ipairs(arc) do
      if sp.t and sp.t >= pickT then iAt = i2; break end
    end
    if iAt then
      local ahead = math.floor((#arc - iAt) * CFG.Grab.CatchLead)
      local sp = arc[math.min(iAt + math.max(ahead, 1), #arc)]
      if sp and sp.p then
        local lead = (sp.p - pick) * FLAT
        -- дальше своей досягаемости не убегаем: цель всё ещё хват, а не гонка
        if lead.Magnitude > JP.reachY() then lead = lead.Unit * JP.reachY() end
        goTo = pick + lead
        HUB.grabLead = math.floor(lead.Magnitude*10)/10
      end
    end
  end

  local airborne = (sAttr(chr(), "InAir") == true)
  if airborne or pickRun > CFG.Grab.CatchStand then
    steerTo(goTo, "grab")
  else
    stopSteerSoft("grab")
  end

  faceBall(pick, dt, CFG.Grab.CatchFaceRate)
  local bp = (ballTrueNow(posOf(info.ball), BALL.vel, BALL.stale))

  if pickDy > CFG.Grab.ArmReach and not airborne then
    local lead = JP.jumpLead(pickDy)
    if pickT <= lead then
      PBX.gs("catch jump", pickDy)
      doJump(("catch: %.1f stds, dy %+.1f, in %.0f ms"):format(pickRun, pickDy, pickT*1000),
             bp or pick, dt, pick, pickT, pickDy)
    else
      PBX.gs("catch: waiting for jump window", pickT - lead)
    end
  elseif airborne then
    PBX.gs("catch: steering in the air", pickRun)
  else
    PBX.gs("catch on the ground", pickDy)
  end
end))))

local function findMovement()
  local m = HUB.mov
  if m and rawget(m, "AutoGuardSpeed") ~= nil then return m end
  if not filtergc then return nil end
  local ok, r = pcall(filtergc, "table",
    { Keys = { "AutoGuardSpeed", "LastAutoGuardTime", "CurrentMovementType" } }, true)
  HUB.mov = (ok and type(r) == "table") and r or nil
  return HUB.mov
end

local function guardSpot(target, me)
  local D = CFG.Defense
  local tp = posOf(sChild(target, "HumanoidRootPart")); if not tp then return nil end
  local goal = goalPosOf(target) or defendGoalPos(target); if not goal then return nil end

  local vel = charVel(target)

  local flatT, flatG = tp*FLAT, goal*FLAT
  if (flatG-flatT).Magnitude < 0.1 then return nil end
  local cf = CFrame.new(flatT, flatG)

  local act = sAttr(target, "Action")
  local latK = (act == "Dribbling") and D.LeadLatDrib or D.LeadLat
  local lat  = cf.RightVector:Dot(vel) * latK
  local fwd  = cf.LookVector:Dot(vel) * D.LeadFwd
  local stand = (PBX.SHOT_PROJ[act] or PBX.SHOT_RIM[act]) and D.StandShoot or D.StandBase

  local dT = (flatT - flatG).Magnitude
  local dU = ((me*FLAT) - flatG).Magnitude
  local ahead = dT < dU
  local gap = math.abs(dU - dT)

  local blowby = false
  if vel.Magnitude > 0.01 and cf.LookVector:Dot(vel.Unit) > D.BlowbyDot then
    blowby = vel.Magnitude > D.BlowbySpeed and gap < D.BlowbyGap
  end

  local spot
  if blowby then
    spot = flatT + cf.LookVector*D.BlowbyAhead + (vel*0.3)*FLAT
  else
    spot = cf.Position + cf.LookVector*stand
                       + cf.LookVector*(fwd < 0 and 0 or fwd)
                       + cf.RightVector*lat
  end

  local sprint
  if blowby then sprint = true
  elseif ((me*FLAT) - spot*FLAT).Magnitude > D.SprintDist or ahead then
    local stam = sAttr(chr(), "Stamina")
    sprint = (type(stam) ~= "number") or (stam > D.StaminaMin)
  else sprint = ahead end
  return spot, sprint, blowby
end

track(RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(dt)
  if not HUB.running then return end

  local function releaseG()
    if HUB.holdG then
      HUB.bypass = true
      pcall(Mt.FireServer, InputSvc:FindFirstChild("HoldG"), { HoldingG = false })
      HUB.bypass = false
      HUB.holdG = false
    end
  end

  local function defOff()
    releaseG()
    stopSteer("defense")
    HUB.defActive = false
  end
  if not CFG.Defense.Enabled then defOff(); return end

  if CFG.Grab.OnlyInMatch and not PBX.inMatch() then
    HUB.defWhy = "not in a match"; defOff(); return
  end
  if hasBall(chr()) then defOff(); return end
  local me = selfPos(); if not me then defOff(); return end

  local hoopHere = (CFG.Defense.HoopRad > 0) and hoopWeDefend() or nil
  local target, bd, skipped = nil, nil, 0
  for _, c in ipairs(charsList()) do
    if isEnemy(c) and hasBall(c) then
      local cp = posOf(sChild(c, "HumanoidRootPart"))
      if cp then
        local nearHoop = true
        if hoopHere then
          nearHoop = ((cp - hoopHere) * FLAT).Magnitude <= CFG.Defense.HoopRad
        end
        if not nearHoop then
          skipped += 1
        else
          local d = ((cp-me)*FLAT).Magnitude
          if d <= CFG.Defense.Engage and (not bd or d < bd) then target, bd = c, d end
        end
      end
    end
  end
  if not target and skipped > 0 then
    dbg("defense", ("carrier exists but farther than %.0f stds from our hoop")
      :format(CFG.Defense.HoopRad))
  end
  if not target then
    defOff()
    dbg("defense", "no enemy carrier within "..CFG.Defense.Engage.." stds")
    return
  end

  if CFG.Defense.HoldG and not HUB.holdG then
    HUB.bypass = true
    pcall(Mt.FireServer, InputSvc:FindFirstChild("HoldG"), { HoldingG = true })
    HUB.bypass = false
    HUB.holdG = true
  end

  local m = findMovement()
  if m and rawget(m, "AutoGuard") == true then pcall(function() m.AutoGuard = false end) end

  local spot, sprint = guardSpot(target, me)
  if not spot then

    dbg("defense", ("spot not computed: target %s, his hoop %s")
      :format(target.Name, tostring(goalPosOf(target) ~= nil)))
    defOff()
    return
  end
  -- ОГРАНИЧИТЕЛЬ ОТРЫВА СТОЯЛ ПОСЛЕ ХОДЬБЫ И НИЧЕГО НЕ ДЕЛАЛ.
  -- Он подрезал spot уже ПОСЛЕ steerToDir, а дальше spot не читался вообще:
  -- StandBase и BlowbyAhead были настройками без единого эффекта, и на
  -- проходе мы гнались за точкой, улетевшей далеко за самого атакующего.
  local tp = posOf(sChild(target, "HumanoidRootPart"))
  if tp then
    local off = (spot - tp) * FLAT
    local lim = CFG.Defense.StandBase + CFG.Defense.BlowbyAhead
    if off.Magnitude > lim then spot = tp + off.Unit * lim end
  end

  local flat = (spot - me) * FLAT
  local gap  = flat.Magnitude
  local dir  = (gap <= CFG.Defense.Deadzone) and Vector3.new() or flat.Unit

  -- ОБХОД ПОДОПЕЧНОГО, А НЕ ХОДЬБА СКВОЗЬ НЕГО.
  -- Точка защиты почти всегда ЗА соперником (между ним и кольцом), поэтому
  -- прямая к ней проходит прямо через его тело. В журнале это видно как
  -- «target at 5.5 stds, spot 7.8 away»: цель ближе, чем точка, то есть он
  -- ровно на пути. Игра в ответ расталкивает (Collision:136 двигает
  -- HumanoidRootPart), и мы топчемся на месте. Если он в коридоре по курсу —
  -- добавляем поперечную составляющую и обходим с той стороны, где короче.
  if tp and dir.Magnitude > 0.05 and CFG.Defense.WalkAround > 0 then
    local toHim = (tp - me) * FLAT
    local ahead = toHim:Dot(dir)
    if ahead > 0.1 and ahead < gap + 1.0 then
      local side = toHim - dir * ahead
      local lat  = side.Magnitude
      local need = CFG.Defense.WalkAround
      if lat < need then
        local px = Vector3.new(-dir.Z, 0, dir.X)
        if lat > 0.05 and px:Dot(side) > 0 then px = -px end
        local w = (need - lat) / need
        local nd = dir + px * w * 1.2
        if nd.Magnitude > 0.05 then
          dir = nd.Unit
          HUB.defWhy = ("going around him (%.1f stds off the line)"):format(lat)
        end
      end
    end
  end

  local out
  if gap > CFG.Defense.SnapDist or dir.Magnitude < 0.05 then
    out = dir
    HUB.defDir = dir
  else
    local prev = HUB.defDir or dir
    local sm = prev:Lerp(dir, math.clamp(dt * CFG.Defense.Speed, 0, 1))
    HUB.defDir = sm
    out = (sm.Magnitude > 0.05) and sm.Unit or Vector3.new()
  end
  steerToDir(out, sprint, "defense")
  HUB.defActive = true

  -- РАЗВОРОТ НА ПОДОПЕЧНОГО, И ОН ЖЕ ЧИНИТ ДРОПДАУН Face.
  -- Ходьба задавалась, а поворот нет: тело оставалось там, куда его развернул
  -- прошлый кадр, и мы регулярно закрывали атакующего спиной. При этом
  -- настройки Face (режим, скорость, сглаживание) лежат в ЭТОЙ секции, а
  -- применялись только внутри тика Auto Move — при выключенном Auto Move
  -- дропдаун в секции защиты не делал вообще ничего. Теперь владелец один.
  -- Когда Auto Move включён, поворот остаётся за ним, чтобы не крутить дважды.
  local fm = CFG.Face.Mode
  if fm ~= "Off" and tp and not (CFG.Move2.Enabled and CFG.Grab.Enabled) then
    local ft = tp
    if fm == "Ball" and BALL.pos then
      ft = (ballTrueNow(BALL.pos, BALL.vel, BALL.stale)) or tp
    end
    faceBall(ft, dt, CFG.Face.Rate, CFG.Face.Smooth)
  end

  dbg("defense", ("target %s at %.1f stds, spot %.1f away, sprint=%s, hook=%s, applied=%s")
    :format(target.Name, bd or -1, gap,
            tostring(sprint), tostring(HUB.moveSrc), tostring(HUB.moveOK)))

end)))

local BL = { state = "idle", gen = 0, realCF = nil, foeM = weakKeys({}),
             target = nil, heldG = false, doneAt = 0 }

local function blatantHold(cf)
  local pc = proxyPart(); if not pc then return false end

  if not cf then return false end
  local p = cf.Position
  if p ~= p or math.abs(p.X) > 1e6 or math.abs(p.Y) > 1e6 or math.abs(p.Z) > 1e6 then
    dbg("blatant", "target position not finite, refused")
    return false
  end

  local lv = cf.LookVector
  if lv ~= lv then dbg("blatant", "target rotation NaN, refused"); return false end
  local ref = BL.realCF and BL.realCF.Position
  if ref then
    local far = (p - ref).Magnitude
    if far > CFG.Blatant.MaxDist * 1.5 then
      dbg("blatant", ("target out of range: %.0f stds from start (limit %.0f)")
        :format(far, CFG.Blatant.MaxDist * 1.5))
      return false
    end
  end
  return tpProxy(pc, cf)
end

local function blatantRelease()
  BL.gen += 1
  -- СТОЙКУ ЗДЕСЬ НЕ СНИМАЕМ, ЕСЛИ ЕЁ ВРЕМЯ ЕЩЁ НЕ ВЫШЛО.
  -- Раньше выход из подмены позиции гасил и стойку, поэтому она жила ровно
  -- HoldTime = 0.12 с. Контест за это время не набирается. Теперь за стойку
  -- отвечает BL.gUntil, а снимает её отдельный присмотр ниже.
  if BL.heldG and R.HoldG and not (BL.gUntil and os.clock() < BL.gUntil) then
    BL.heldG = false
    BL.gUntil = nil
    HUB.bypass = true
    pcall(Mt.FireServer, R.HoldG, { HoldingG = false })
    HUB.bypass = false
  end
  if BL.state ~= "hold" then BL.state = "idle"; HUB.blatantHolding = false; return end
  holdRelease()

  BL.heldFrom = nil
  BL.wantG, BL.wantJump, BL.jumped = false, false, false
  HUB.blatantHolding = false
  BL.state = BL.provisional and "idle" or "done"
  BL.provisional = false
  BL.doneAt = os.clock()
  if CFG.Blatant.Restore and BL.realCF then
    local pc = proxyPart()
    if pc then tpProxy(pc, BL.realCF) end
  end
  -- ВТОРОЙ ПУТЬ, КОТОРЫМ НАКРЫТИЕ ОТМЕНЯЛО НАШ СОБСТВЕННЫЙ УДАР.
  -- Вход мы уже закрыли проверкой shotAlive, но выход слал Shoot=false
  -- безусловно. Достаточно подобрать мяч в момент удержания — и релиз
  -- уходил серверу поверх нашего броска, тот ставил Debounce, бросок
  -- отменялся. Шлём отмену только когда своего броска в работе нет.
  local shotAlive = PBX.pendActive() or (sAttr(chr(), "Action") == "Shooting")
  HUB.bypass = true
  if not shotAlive then
    pcall(Mt.FireServer, R.Shoot, { Shoot = false })
  end
  -- Обнуление курса нужно, только если мы сами что-то отправляли: иначе это
  -- просто команда «стой» поверх живого ввода игрока.
  if HUB.lastDir then
    pcall(Mt.FireServer, R.Move, Vector3.new(0,0,0))
    HUB.lastDir = nil
  end
  if HUB.sprintOn then pcall(Mt.FireServer, R.Sprint, false); HUB.sprintOn = false end
  HUB.bypass = false
end

local function contestEngage(c, why, provisional)
  local B = CFG.Blatant
  if not (HUB.running and B.Enabled) then return false end

  if BL.state == "hold" and BL.target == c then
    if not provisional then
      BL.provisional = false
      BL.heldFrom = BL.heldFrom or os.clock()
      HUB.blatantWhy = ("holding %s (%s)"):format(c.Name, why)
    end
    return true
  end
  if BL.state ~= "idle" then return false end
  if CFG.Grab.OnlyInMatch and not PBX.inMatch() then return false end
  if hasBall(chr()) then return false end
  if not (c and c.Parent) then return false end

  local me = selfPos(); if not me then return false end
  local hp = hoopWeDefend(); if not hp then HUB.blatantWhy = "no hoop"; return false end
  local cp = posOf(sChild(c, "HumanoidRootPart"))
  if not cp then return false end

  if ((cp - hp) * FLAT).Magnitude > B.HoopRad then
    HUB.blatantWhy = "shooter too far from the hoop"; return false
  end
  local d = (cp - me).Magnitude
  if d > B.MaxDist then HUB.blatantWhy = "shooter out of reach"; return false end

  local pc = proxyPart(); if not pc then return false end
  local okc, realCF = pcall(RDR.CFrame, pc)
  if not okc then return false end
  if not physAllowed() then
    HUB.blatantWhy = "server is forcing our position"; return false
  end

  BL.realCF, BL.target, BL.heldFrom = realCF, c, os.clock()
  BL.state = "hold"
  HUB.blatantHolding = true
  BL.provisional = provisional and true or false
  BL.gen += 1

  -- ЧТО ДЕЛАЕМ, ЗАВИСИТ ОТ ТОГО, ЧЕМ ОН АТАКУЕТ.
  -- Обычный бросок накрывается СТОЙКОЙ: контест начисляется за защитника
  -- рядом, а прыжок на джампшоте только уводит нас с земли. Данк и лэйап идут
  -- выше кольца — там нужен ПРЫЖОК, стойка внизу бесполезна.
  local isRim = (why == "rim attack") or (function()
    local a = sAttr(c, "Action")
    return a == "Dunking" or a == "ContactLayup"
  end)()
  BL.wasRim = isRim

  -- НАМЕРЕНИЯ, А НЕ ОДИН ВЫСТРЕЛ В ПУСТОТУ.
  -- Прежний код слал HoldG ровно ОДИН раз и считал дело сделанным. Пакет
  -- может не дойти, сервер может его отбросить (в этот момент как раз идёт
  -- подмена позиции), и стойки просто не было — а снаружи это "он даже
  -- защиту не удерживает". Теперь держим НАМЕРЕНИЕ, а тик повторяет отправку,
  -- пока сервер не подтвердит атрибутом HoldingG.
  BL.wantG    = (B.HoldG and R.HoldG and not isRim) and true or false
  BL.wantJump = isRim and true or false
  BL.jumped, BL.gSent, BL.gAt = false, 0, 0
  -- Стойка начинается СЕЙЧАС, в момент обнаружения, и живёт своё время.
  BL.gUntil = BL.wantG and (os.clock() + B.StanceTime) or nil

  -- ФАЛЬШИВЫЙ БРОСОК УБРАН СОВСЕМ.
  -- Он слал Shoot=true, Jump и через 0.12 с Shoot=false мимо нашего же хука.
  -- Ради накрытия это не нужно: контест считается за присутствие защитника и
  -- за прыжок, а лишний релиз только рисковал оборвать собственный бросок
  -- игрока. Для данка шлём ЧИСТЫЙ Jump, физику дальше ведёт игра.
  HUB.blatantWhy = ("engaged %s at %.1f (%s)"):format(c.Name, d, why)
  return true
end

-- ПРИСМОТР ЗА СТОЙКОЙ, НЕЗАВИСИМО ОТ ПОДМЕНЫ ПОЗИЦИИ.
-- Подмена длится доли секунды, стойка — своё время. Пока оно идёт, при
-- необходимости переотправляем; когда вышло — снимаем ровно один раз.
track(RunService.Heartbeat:Connect(function()
  if not (HUB.running and BL.gUntil) then return end
  if os.clock() < BL.gUntil then
    if R.HoldG and sAttr(chr(), "HoldingG") ~= true
       and os.clock() - (BL.gAt or 0) > 0.12 then
      BL.gAt = os.clock()
      BL.gSent = (BL.gSent or 0) + 1
      HUB.bypass = true
      pcall(Mt.FireServer, R.HoldG, { HoldingG = true })
      HUB.bypass = false
    end
    return
  end
  BL.gUntil = nil
  if BL.heldG and R.HoldG then
    BL.heldG = false
    HUB.bypass = true
    pcall(Mt.FireServer, R.HoldG, { HoldingG = false })
    HUB.bypass = false
  end
end))

track(RunService.Heartbeat:Connect(function(dt)
  if not HUB.running then return end
  local B = CFG.Blatant

  if not B.Enabled or (CFG.Grab.OnlyInMatch and not PBX.inMatch()) then
    if BL.state == "hold" then blatantRelease() end

    HUB.blatantWhy = (not B.Enabled) and "disabled" or "not in a match"
    BL.state = "idle"; HUB.blatantHolding = false; return
  end
  if hasBall(chr()) then
    if BL.state == "hold" then blatantRelease() end
    BL.state = "idle"; HUB.blatantHolding = false; HUB.blatantWhy = "we have the ball"; return
  end

  if BL.state == "hold" then
    local tgt = BL.target
    if not (tgt and tgt.Parent) then
      blatantRelease(); HUB.blatantWhy = "target gone"; return
    end

    if BL.provisional then
      BL.since = BL.since or os.clock()
      -- ПОЧЕМУ ЗДЕСЬ БОЛЬШЕ НЕТ ПРОВЕРКИ shotKind.
      -- Вход по метру соперника срабатывает ДО того, как его Action станет
      -- броском: в том и смысл, метр виден раньше анимации. Прежнее условие
      -- требовало shotKind == "windup" уже на следующем кадре, а там ещё
      -- "Dribbling", и подмена снималась через кадр после установки с текстом
      -- "windup ended without a shot". Накрытие мигало вместо удержания.
      -- Держим по времени, досрочно снимаем только если мяча у него уже нет.
      local gone = not hasBall(tgt)
      if gone or os.clock() - BL.since > B.HoldTime then
        blatantRelease()
        HUB.blatantWhy = gone and "he let the ball go"
          or ("held %.0f ms"):format((os.clock() - BL.since)*1000)
        BL.since = nil
        return
      end
    else

      BL.since = nil
      BL.heldFrom = BL.heldFrom or os.clock()
      if os.clock() - BL.heldFrom > B.HoldTime then
        blatantRelease()
        HUB.blatantWhy = ("held %.0f ms"):format((os.clock() - BL.heldFrom)*1000)
        return
      end
    end
    -- СТОЙКА ДЕРЖИТСЯ ДО ПОДТВЕРЖДЕНИЯ СЕРВЕРОМ.
    if BL.wantG and R.HoldG and sAttr(chr(), "HoldingG") ~= true then
      if os.clock() - (BL.gAt or 0) > 0.12 then
        BL.gAt = os.clock()
        BL.gSent = (BL.gSent or 0) + 1
        BL.heldG = true
        HUB.bypass = true
        pcall(Mt.FireServer, R.HoldG, { HoldingG = true })
        HUB.bypass = false
      end
    end
    -- ПРЫЖОК НА ДАНК: один раз, и только с земли.
    -- Слать Jump в воздухе бессмысленно, а физику подъёма ведёт сама игра —
    -- мы в неё не вмешиваемся (в хуке скорости стоит выход по InAir).
    if BL.wantJump and not BL.jumped and R.Jump
       and sAttr(chr(), "InAir") ~= true then
      BL.jumped = true
      HUB.bypass = true
      pcall(Mt.FireServer, R.Jump)
      HUB.bypass = false
    end

    local cp = posOf(sChild(tgt, "HumanoidRootPart"))
    local hp = hoopWeDefend()
    if cp and hp then
      local toHoop = (hp - cp) * FLAT
      if toHoop.Magnitude > 0.1 then
        -- ВСТАЁМ МЕЖДУ НИМ И КОЛЬЦОМ, ЛИЦОМ К НЕМУ.
        -- toHoop смотрит от врага к нашему кольцу, значит точка на Gap студов
        -- в эту сторону — прямо перед ним по ходу его атаки, а lookAtCF
        -- разворачивает нас на него.
        local rise = B.RiseY
        -- НА ДАНКЕ И ЛЭЙАПЕ ПОДНИМАЕМСЯ ВЫШЕ: там мяч идёт над кольцом, и
        -- накрывать его на уровне груди бессмысленно.
        local act = sAttr(tgt, "Action")
        if act == "Dunking" or act == "ContactLayup" or act == "Rebounding" then
          rise = rise + B.DunkRise
        end
        local spot = cp + toHoop.Unit * B.Gap + Vector3.new(0, rise, 0)
        local cf = lookAtCF(spot, cp, proxyPart())
        if cf then blatantHold(cf) end
      end
    end
    return
  end

  if BL.state == "done" then
    if os.clock() - (BL.doneAt or 0) > B.Cooldown then BL.state = "idle" else return end
  end

  local me = selfPos(); if not me then return end
  local hp = hoopWeDefend(); if not hp then HUB.blatantWhy = "no hoop"; return end
  local best, bd, bk
  for _, c in ipairs(charsList()) do
    local k = isEnemy(c) and PBX.shotKind(c) or nil
    local want = (k == "rim") or (k == "windup" and B.OnWindup)
    -- ВХОД ПО МЕТРУ ВРАГА: не ждём, пока Action станет броском.
    -- ВАЖНО: в покое meterOffset стоит НЕ на нуле, а на ~1.4..1.47 (замер по
    -- пяти дампам). Голое сравнение «метр >= порога» выполнялось всегда, и
    -- накрывать выбегали на любого врага с мячом — отсюда «телепортирует
    -- слишком часто». Признак настоящего броска тот же, что у нашего метра:
    -- сначала СБРОС ниже ResetBelow, и только потом рост. Без сброса не входим.
    if not want and isEnemy(c) and B.MeterTrigger > 0 then
      local mv = sAttr(c, "meterOffset")
      local m
      if typeof(mv) == "Vector2" then
        local ax, ay = math.abs(mv.X), math.abs(mv.Y); m = (ay > ax) and ay or ax
      elseif type(mv) == "number" then m = math.abs(mv) end
      local st = BL.foeM[c]
      if not hasBall(c) then
        BL.foeM[c] = nil
      elseif m then
        if m < CFG.ResetBelow then
          st = st or {}
          st.armed, st.at = true, os.clock()
          BL.foeM[c] = st
        elseif st and st.armed then
          -- метр пошёл вверх после сброса: это живой бросок
          if os.clock() - (st.at or 0) > 1.5 then
            BL.foeM[c] = nil            -- затянулось, это не бросок
          elseif m >= B.MeterTrigger and m < 1.15 then
            -- метр обязан РАСТИ: одиночный выброс это не бросок
            if st.prev and m > st.prev + 0.005 then
              want, k = true, "windup"
              HUB.blatantMeter = math.floor(m*1000)/1000
            end
          end
          if st then st.prev = m end
        end
      end
    end
    if want then
      local cp = posOf(sChild(c, "HumanoidRootPart"))
      if cp and ((cp - hp) * FLAT).Magnitude <= B.HoopRad then
        local d = (cp - me).Magnitude
        if d <= B.MaxDist and (not bd or d < bd) then best, bd, bk = c, d, k end
      end
    end
  end
  if not best then HUB.blatantWhy = "nobody attacking"; return end
  contestEngage(best, bk == "windup" and "windup" or "rim attack", bk == "windup")
end))

if R.MReg then
  track(R.MReg.OnClientEvent:Connect(function(character)
    if not (HUB.running and CFG.Blatant.Enabled) then return end
    if character and isEnemy(character) then
      contestEngage(character, "shot registered")
    end
  end))
end

track(RunService.Heartbeat:Connect(function()
  if not (CFG.Stamina.Enabled and HUB.running) then return end
  local c = chr(); if not c then return end
  pcall(function() c:SetAttribute("Stamina", CFG.Stamina.Value) end)
end))

local function unstick()
  local pc = proxyPart()

  holdRelease()
  -- Кнопка паники обязана гасить И флаг накрытия: по нему тик перехвата
  -- решает молчать, и оставшийся true заблокировал бы перехват навсегда.
  BL.state = "idle"
  HUB.blatantHolding = false
  BL.provisional, BL.heldFrom, BL.since, BL.heldG = false, nil, nil, false
  if pc then pcall(function() pc.Anchored = false end) end

  if BL.realCF then tpProxy(pc, BL.realCF)
  else
    local hp = posOf(sChild(chr(), "HumanoidRootPart"))
    if pc and hp then tpProxy(pc, CFrame.new(hp)) end
  end
  HUB.bypass = true
  pcall(Mt.FireServer, R.Sprint, false)
  pcall(Mt.FireServer, R.Move, Vector3.new(0,0,0))
  pcall(Mt.FireServer, R.Shoot, { Shoot = false })
  HUB.bypass = false
  removeMoveHook()
  HUB.gen += 1; PBX.pendClear()
  notify("proxy restored, input override cleared")
end

local function enc(v, d)
  d = d or 5
  local t = typeof(v)
  if v == nil then return "null"
  elseif t=="number" then return (v~=v or v==math.huge or v==-math.huge) and "null" or string.format("%.6g",v)
  elseif t=="boolean" then return tostring(v)
  elseif t=="string" then return '"'..v:gsub('[%c\\"]',function(c)
      local m={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
      return m[c] or string.format('\\u%04x',c:byte()) end)..'"'
  elseif t=="Vector3" then return string.format('{"x":%.4g,"y":%.4g,"z":%.4g}',v.X,v.Y,v.Z)
  elseif t=="table" then
    if d<=0 then return '"<deep>"' end
    local n,arr=0,true
    for k in pairs(v) do n+=1; if type(k)~="number" then arr=false end end
    local p={}
    if arr then for i=1,n do p[#p+1]=enc(v[i],d-1) end return "["..table.concat(p,",").."]" end
    for k,val in pairs(v) do p[#p+1]=enc(tostring(k),d-1)..":"..enc(val,d-1) end
    return "{"..table.concat(p,",").."}"
  else return enc(tostring(v), d-1) end
end

local function save()

  table.clear(REPORT)
  local tagged = (function() local ok,t=pcall(function() return #CollSvc:GetTagged("Basketballs") end) return ok and t or -1 end)()
  local nLines = 0; for _ in pairs(lines) do nLines += 1 end
  local meta = {
    version = VERSION, myName = LP.Name, myChar = sFull(chr()),
    ping = dataPing(), pingSource = HUB.pingSource, pingFails = HUB.pingFails,
    stats = HUB.stats, shotCount = HUB.shotsTotal or #HUB.shots,
    shotsKept = #HUB.shots,
    cfg = { Target = CFG.Target, PingBase = CFG.PingBase, PingCoef = CFG.PingCoef,
            RateFlat = CFG.RateFlat, UseFittedRate = CFG.UseFittedRate,
            RateLo = CFG.RateLo, RateHi = CFG.RateHi, RateMinN = CFG.RateMinN,
            TickRate = CFG.TickRate, MinFitN = CFG.Traj.MinFitN,
            BlockRange = CFG.Grab.BlockRange, BlockCone = CFG.Grab.BlockCone,
            HoopRad = CFG.Grab.HoopRad, LeadTime = CFG.Grab.LeadTime },
    foreign = HUB.foreign, greenValLast = HUB.greenVal,

    theirMeter = HUB.theirMeter, shootTime = CFG.Grab.ShootTime,

    jumpLag = HUB.jumpLag, jumpLagN = HUB.jumpLagN, jumpLagMiss = HUB.jumpLagMiss,
    srvNow = srvNow(),
    arcEffBuckets = HUB.arcEffB, jumpLagBad = HUB.jumpLagBad,

    antiOn = CFG.AntiDef.Enabled, antiWhy = HUB.antiWhy,

    antiPreShot = CFG.AntiDef.PreShot, antiShot = HUB.antiShot,
    antiAgo = HUB.antiAt and (os.clock() - HUB.antiAt) or nil,
    slipEnabled = CFG.Move.Slip.Enabled, slipKeepAgo = HUB.slipKeep
      and (os.clock() - HUB.slipKeep) or nil,

    turnSrc = HUB.turnSrc, turnOK = HUB.turnOK,
    slipHitAct = HUB.slipHitAct, slipLog = SLIPLOG,
    slipHitAgo = HUB.slipHit and (os.clock() - HUB.slipHit) or nil,
    slipAngledAgo = HUB.slipOn and (os.clock() - HUB.slipOn) or nil,
    blatantG = BL.gSent, blatantJumped = BL.jumped, blatantRim = BL.wasRim,
    errN = HUB.errN, errs = HUB.errs, lastErr = HUB.lastErr,
    smart3 = HUB.smart3Info, s3Why = HUB.s3Why,
    arcSrc = A3.src, s3Line = CFG.S3.LineDist, faceWhy = HUB.faceWhy,
    autoWhy = HUB.autoWhy, spotWhy = HUB.spotWhy,
    inMatch = PBX.inMatch(), onlyInMatch = CFG.Grab.OnlyInMatch,
    grabStats = HUB.gs, catchOn = CFG.Grab.Catch,
    defWhy = HUB.defWhy, spoofInfo = HUB.spoofInfo,
    -- autoOn — это Auto Move, а НЕ Auto Green. Из-за путаницы состояние
    -- Auto Green трижды приходилось выводить косвенно, по пустому shots[].
    autoGreenOn = CFG.Enabled, zeroOn = CFG.Zero.Enabled,
    autoMoveOn = CFG.Move2.Enabled,
    autoOn = CFG.Move2.Enabled,
    slipOnCfg = CFG.Move.Slip.Enabled, rimZone = CFG.Grab.RimZone,
    turnAppliedAgo = HUB.turnApplied and (os.clock() - HUB.turnApplied) or nil,
    wantYaw = HUB.wantYaw, faceBallOn = CFG.Grab.FaceBall,

    fitDropped = HUB.fitDropped, arcEff = HUB.arcEff, arcEffN = HUB.arcEffN,

    arcEffSrc = HUB.aeSrc, arcEffPkgs = PBX.AE.pkgs and (function()
      local n = 0; for _ in pairs(PBX.AE.pkgs) do n = n + 1 end; return n end)() or nil,
    jumpLagFallback = CFG.Grab.JumpLagFallback * dataPing(),

    jumpApex = HUB.jumpApex, jumpApexN = HUB.jumpApexN,
    jumpApexBad = HUB.jumpApexBad, reachY = JP.reachY(),
    blockWhy = HUB.blockWhy, grabWhy = HUB.grabWhy,

    trajDuration = CFG.Traj.Duration, physDuration = CFG.Traj.PhysDuration,
    hoopDist = HUB.lastHoopDist,
    hoopTol  = HUB.lastHoopTol,
    hoopTolAt = HUB.lastHoopT,

    scoreDist = HUB.scoreDist, scoreRad = CFG.Traj.ScoreRad,
    arcBounces = HUB.arc and HUB.arc.arc and HUB.arc.arc.bounces or nil,
    skipMakes = CFG.Grab.SkipMakes, preCatch = CFG.Grab.PreCatch,
    antiTest = HUB.antiTest,

    slipFoes = HUB.slipFoes, slipZone = HUB.slipZone,
    slipJuke = HUB.slipJuke, slipFace = HUB.slipFace,
    slipMode = CFG.Move.Slip.Mode, slipWhy = HUB.slipWhy,
    matchLive = PBX.matchLive(),
    slipNear = HUB.slipNear,

    slipPress = HUB.slipPress, slipSep = HUB.slipSep,
    noclipParts = HUB.noclipParts, ghostParts = HUB.ghostParts,
    goalRadBase = CFG.Grab.GoalRad, maxSlack = CFG.Traj.MaxSlack,
    target = CFG.Target,
    shotCancelled = HUB.shotCancelled, shotDead = HUB.shotDead,
    pingBase = CFG.PingBase, pingCoef = CFG.PingCoef,

    ballsTagged = tagged,
    ballState = BALL.state, ballSpeed = BALL.speed, ballVelSource = BALL.velSrc,
    ballStale = BALL.stale, renderLag = CFG.Traj.RenderLag,
    ballFitN = BALL.fitN, minFitN = CFG.Traj.MinFitN,
    ballHolder = BALL.holder and BALL.holder.Name or nil,
    ballShooter = BALL.shooter and BALL.shooter.Name or nil,
    shooterIsEnemy = BALL.shooter and isEnemy(BALL.shooter) or nil,
    trajVisible = trajVisible(),
    ourGoal = ourGoalPos(), defendGoal = defendGoalPos(BALL.shooter),
    goalFromShooter = BALL.shooter and (goalPosOf(BALL.shooter) ~= nil) or false,
    hoopCount = #hoopList(), defendHoop = hoopWeDefend(), defendSource = HUB.defendSrc,
    hoopSource = hoopSrc, courtNumber = sAttr(chr(), "CourtNumber"),
    gamemode = (function() local m; pcall(function() m=Workspace:GetAttribute("Gamemode") end) return m end)(),

    matchSrc = PK.src, matchSide = PK.side, matchSize = PK.n,
    matchCourt = PK.court and PK.court.Name or nil,
    matchRef = PK.ref and PK.ref.Name or nil,

    courtType = PK.court and sAttr(PK.court, "CourtType") or nil,
    courtHoops = PK.court and sAttr(PK.court, "Hoops") or nil,

    matchBall = HUB.matchBall,

    myTeam = sAttr(chr(), "Team"),

    attrsRaw = (function()
      local t = {}
      pcall(function()
        for k, v in pairs(chr():GetAttributes()) do t[k] = tostring(v) end
      end)
      return t
    end)(),
    attrsFolder = (function()
      local t = {}
      pcall(function()
        local f = sChild(chr(), "Attributes")
        if not f then return end
        for _, o in ipairs(f:GetChildren()) do
          local okv, val = pcall(RDR.Value, o)
          t[o.Name] = okv and tostring(val) or ("<"..o.ClassName..">")
        end
      end)
      return t
    end)(),
    roster = (function()
      local t = {}
      -- Выгрузке нужен ВЕСЬ сервер: по ней считаются чужие матчи.
      for _, c in ipairs(charsAll()) do

        local gp = goalPosOf(c)
        t[#t+1] = { name = c.Name, team = sAttr(c,"Team"),
                    home = sAttr(c,"HomeTeam"), tidx = sAttr(c,"TeamIndex"),
                    side = PK.names[c.Name],
                    enemy = isEnemy(c), mate = isMate(c),
                    ball = hasBall(c) and true or false,
                    goalX = gp and (math.floor(gp.X*10)/10) or nil,
                    goalZ = gp and (math.floor(gp.Z*10)/10) or nil,
                    action = sAttr(c,"Action"),
                    speed = math.floor(charVel(c).Magnitude*10)/10 }
      end
      return t
    end)(),
    movementFound = (HUB.mov ~= nil), autoGuardOn = HUB.mov and rawget(HUB.mov,"AutoGuard") or nil,

    moveHook = (HUB.moveWorld ~= nil), moveSource = HUB.moveSrc,
    moveControlsFrom = HUB.pmSrc, moveEffective = HUB.moveOK,
    moveMissStreak = HUB.moveBad, moveHooksCount = HUB.pmCount,
    moveSeenMagnitude = HUB.moveSeen,
    canMove = sAttr(chr(), "CanMove"),
    unfroze = HUB.unfroze,
    stuckWho = HUB.stuckWho, stuckFor = HUB.stuckFor, stuckVelHook = HUB.stuckVelHook,
    forceMoveDir = tostring(sAttr(chr(), "ForceMoveDirection")),
    serverVel = tostring(sAttr(chr(), "ServerVelocity")),
    gameMoveDir = (function()
      local m = HUB.mov; if not m then return nil end
      local ok, v = pcall(RDR.MoveDirection, m)
      return (ok and typeof(v)=="Vector3") and (math.floor(v.Magnitude*100)/100) or nil
    end)(),
    holdG = HUB.holdG, defenseActive = HUB.defActive,

    autoStance = HUB.autoStance, autoHeld = HUB.autoHeld,
    m2Stance = CFG.Move2.Stance, m2Steal = CFG.Move2.Steal,
    m2On = CFG.Move2.Enabled, defenseOn = CFG.Defense.Enabled,

    moveOwner = HUB.moveOwner,

    ballJumps = HUB.ballJumps or 0, ballMaxSpeed = CFG.Traj.MaxSpeed,
    blatantState = BL and BL.state or nil,
    blatantOn = CFG.Blatant.Enabled, blatantWhy = HUB.blatantWhy,
    blatantMeter = HUB.blatantMeter,
    blatantTarget = BL and BL.target and BL.target.Name or nil,
    groundLevel = groundLevel(), charCompFound = (findCharComp() ~= nil),
    trajWhy = (function() local _, why = trajWhy() return why end)(),

    predFitAvg  = (HUB.predQ and HUB.predQ.fit.n  > 0) and (HUB.predQ.fit.sum /HUB.predQ.fit.n ) or nil,

    pred8Avg = (HUB.predQ and HUB.predQ.fit8 and HUB.predQ.fit8.n > 0)
               and (HUB.predQ.fit8.sum / HUB.predQ.fit8.n) or nil,
    pred8Max = HUB.predQ and HUB.predQ.fit8 and HUB.predQ.fit8.max or nil,
    pred8N   = HUB.predQ and HUB.predQ.fit8 and HUB.predQ.fit8.n or 0,

    predShotAvg = (HUB.predQ and HUB.predQ.shot and HUB.predQ.shot.n > 0)
                  and (HUB.predQ.shot.sum / HUB.predQ.shot.n) or nil,
    predShotMax = HUB.predQ and HUB.predQ.shot and HUB.predQ.shot.max or nil,
    predShotN   = HUB.predQ and HUB.predQ.shot and HUB.predQ.shot.n or 0,

    jumpLog = HUB.jumpLog,
    jumpPingUp = CFG.Grab.PingUp,
    predFitMax  = HUB.predQ and HUB.predQ.fit.max  or nil,
    predFitN    = HUB.predQ and HUB.predQ.fit.n    or 0,
    predCheckAt = CFG.Traj.PredCheck,
    arcHits   = HUB.arc and HUB.arc.hits or nil,
    arcHoopDist = HUB.arc and HUB.arc.hoopDist or nil,
    drawingAvailable = (Drawing ~= nil), linesCreated = nLines,
    trajFunnel = HUB.trajFunnel,
    hoopFound = (function() local me=selfPos() return me and (nearestHoop(me)~=nil) or false end)(),
    trajOn = CFG.Traj.Enabled, grabOn = CFG.Grab.Enabled, spoofOn = CFG.Spoof.Enabled, s3On = CFG.S3.Enabled,
  }

  local okN, okP, badN = 0, 0, 0
  for _, sh in ipairs(HUB.shots) do
    if sh.perfectPossible then
      okN += 1; if sh.verdict == "Perfect" then okP += 1 end
    elseif sh.greenVal then badN += 1 end
  end
  rep(("[PB] reachable shots %d, Perfect %d (%.0f%%) | unreachable (green at floor) %d")
    :format(okN, okP, okN>0 and okP/okN*100 or 0, badN))
  if (HUB.shotCancelled or 0) > 0 or (HUB.shotDead or 0) > 0 then
    rep(("[PB] last dead shot: %s"):format(tostring(HUB.deadWhy or "none")))
    rep(("[PB] shots cancelled: %d released before we sent them, %d died before the meter")
      :format(HUB.shotCancelled or 0, HUB.shotDead or 0))
  end
  -- ЭТА СТРОКА СТОЯЛА ВНУТРИ БЛОКА ПРО ОТМЕНЁННЫЕ БРОСКИ И НЕ ПЕЧАТАЛАСЬ,
  -- когда отмен не было — то есть ровно тогда, когда всё в порядке.
  rep(("[PB] auto green=%s | spoof=%s | smart3=%s | zero=%s | intercept=%s | slip=%s")
    :format(tostring(CFG.Enabled), tostring(CFG.Spoof.Enabled), tostring(CFG.S3.Enabled),
            tostring(CFG.Zero.Enabled), tostring(CFG.Grab.Enabled),
            tostring(CFG.Move.Slip.Enabled)))
  rep(("[PB] arc effect source: %s"):format(tostring(HUB.aeSrc or "not computed yet")))
  do
    local rim, rimP, lag, lagN = 0, 0, 0, 0
    for _, sh in ipairs(HUB.shots) do
      if sh.isRim then
        rim += 1
        if sh.verdict == "Perfect" then rimP += 1 end
        if sh.dunkLag then lag += sh.dunkLag; lagN += 1 end
      end
    end
    rep(("[PB] rim attempts timed: %d (Perfect %d) | jump lag %s | dunk timing on=%s")
      :format(rim, rimP,
              lagN > 0 and ("%.3f s avg over %d"):format(lag/lagN, lagN) or "not seen",
              tostring(CFG.TimeDunks)))
  end
  rep(("[PB] 3PT: smart on=%s | line %.1f stds | %s")
    :format(tostring(CFG.S3.Enabled), CFG.S3.LineDist,
            tostring(HUB.s3Why or "no shot yet")))
  rep(("[PB] errors: %d | last: %s")
    :format(HUB.errN or 0, tostring(HUB.lastErr or "none")))
  rep(("[PB] ping=%.0fms(%s, fails %d) | k=%.2f -> correction=%.3f | rate=%s")
    :format(dataPing()*1000, HUB.pingSource, HUB.pingFails,
            CFG.PingCoef, pingCorr(),
            CFG.UseFittedRate and "fitted" or "constant"))

  do
    local n, sum, lo, hi, inw = 0, 0, nil, nil, 0
    for _, sh in ipairs(HUB.shots) do
      if type(sh.srvMeter) == "number" then
        n += 1; sum += sh.srvMeter
        if not lo or sh.srvMeter < lo then lo = sh.srvMeter end
        if not hi or sh.srvMeter > hi then hi = sh.srvMeter end
        if sh.srvMeter >= 1.504 and sh.srvMeter <= 1.577 then inw += 1 end
      end
    end
    if n > 0 then
      rep(("[PB] server meter: avg %.3f, range %.3f..%.3f | inside Perfect %d/%d (target %.3f)")
        :format(sum/n, lo, hi, inw, n, CFG.Target))
      -- ГДЕ ЛЕЖИТ PERFECT НА САМОМ ДЕЛЕ, А ГДЕ МЫ.
      -- Вердикт решает сервер, и по одному srvMeter его не предсказать: зоны
      -- Perfect и Good пересекаются. Зато видно СИСТЕМАТИЧЕСКИЙ сдвиг: если
      -- центр наших Perfect стабильно ниже цели, мы недодерживаем именно на эту
      -- величину, и это уже число, а не ощущение.
      local pn, ps, gn, gs = 0, 0, 0, 0
      for _, sh in ipairs(HUB.shots) do
        if type(sh.srvMeter) == "number" and sh.perfectPossible then
          if sh.verdict == "Perfect" then pn += 1; ps += sh.srvMeter
          elseif sh.verdict == "Good" then gn += 1; gs += sh.srvMeter end
        end
      end
      if pn > 0 then
        rep(("[PB] Perfect centre %.4f (n=%d) | Good centre %s | target %.4f | bias %+.4f")
          :format(ps/pn, pn, gn > 0 and ("%.4f"):format(gs/gn) or "-",
                  CFG.Target, ps/pn - CFG.Target))
      end
      -- ЧТО ИМЕННО ИСПОРТИЛО БРОСОК: наш тайминг или контест.
      -- Три «Slightly Late» подряд в дампе имели contest 74..89 и грин в полу —
      -- по таймингу там не выигрывалось ничего, и мешать их с промахами по
      -- времени значит искать причину не там.
      local cn, cs, tn = 0, 0, 0
      for _, sh in ipairs(HUB.shots) do
        local ct = tonumber(sh.contest)
        if ct and ct > 25 then cn += 1; cs += ct
        elseif sh.verdict and sh.verdict ~= "Perfect" and sh.perfectPossible then tn += 1 end
      end
      if cn > 0 or tn > 0 then
        rep(("[PB] misses: %d contested (avg %.0f%%, window floored) | %d pure timing")
          :format(cn, cn > 0 and cs/cn or 0, tn))
      end
    end
  end
  rep(("[PB] ball: tagged=%s state=%s speed=%.1f holder=%s shooter=%s(enemy=%s) visible=%s")
    :format(tostring(tagged), BALL.state, BALL.speed or 0,
            tostring(meta.ballHolder), tostring(meta.ballShooter),
            tostring(meta.shooterIsEnemy), tostring(meta.trajVisible)))
  rep(("[PB] Drawing=%s lines=%d | hoops=%d (%s) | ours=%s | defending=%s (source: %s)")
    :format(tostring(meta.drawingAvailable), nLines, meta.hoopCount,
            tostring(meta.hoopSource),
            tostring(meta.ourGoal ~= nil), tostring(meta.defendHoop ~= nil),
            tostring(meta.defendSource)))
  do
    local mine, foes, outside = 0, 0, 0
    for _, r in ipairs(meta.roster or {}) do
      if r.enemy then foes += 1
      elseif r.mate then mine += 1
      elseif r.name ~= meta.myName then outside += 1 end
    end

    rep(("[PB] team: mates %d, enemies %d, other matches %d | Team=%s court=%s mode=%s")
      :format(mine, foes, outside, tostring(meta.myTeam),
              tostring(meta.courtNumber), tostring(meta.gamemode)))
    rep(("[PB] match: %s | side=%s size=%s | courtType=%s hoops=%s | own ball found=%s")
      :format(tostring(meta.matchSrc), tostring(meta.matchSide),
              tostring(meta.matchSize), tostring(meta.courtType),
              tostring(meta.courtHoops), tostring(meta.matchBall)))
    rep(("[PB] movement: %s | override owner: %s | applied=%s (misses in a row %s) | game MoveDirection=%s")
      :format(tostring(meta.moveControlsFrom or "not engaged"),
              tostring(meta.moveOwner), tostring(meta.moveEffective),
              tostring(meta.moveMissStreak), tostring(meta.gameMoveDir)))
    rep(("[PB] contest shooter: on=%s state=%s target=%s | %s")
      :format(tostring(meta.blatantOn), tostring(meta.blatantState),
              tostring(meta.blatantTarget), tostring(meta.blatantWhy)))
    rep(("[PB] ball: position jumps rejected %s | speed limit %s stds/s | current %.1f")
      :format(tostring(meta.ballJumps), tostring(meta.ballMaxSpeed), BALL.speed or 0))

    for _, r in ipairs(meta.roster or {}) do
      if r.side or r.name == meta.myName or not meta.matchSide then
        rep(("[PB]   %s: side=%s enemy=%s ball=%s Goal=%s,%s action=%s speed=%.1f")
          :format(tostring(r.name), tostring(r.side), tostring(r.enemy),
                  tostring(r.ball), tostring(r.goalX), tostring(r.goalZ),
                  tostring(r.action), r.speed or 0))
      end
    end
  end
  rep(("[PB] trajectory: %s | velocity from: %s (points %d, act threshold %d) | render lag %.1fms | freeze %.0fms")
    :format(tostring(meta.trajWhy), tostring(meta.ballVelSource),
            BALL.fitN or 0, CFG.Traj.MinFitN,
            CFG.Traj.RenderLag*1000, (BALL.stale or 0)*1000))
  rep(("[PB] arc: physics %.1fs (%d pts), drawn %.1fs | hoop approach %s vs tolerance %s at %s s")
    :format(CFG.Traj.PhysDuration, CFG.Traj.PhysSamples, CFG.Traj.Duration,
            meta.hoopDist and ("%.1f"):format(meta.hoopDist) or "-",
            meta.hoopTol and ("%.1f"):format(meta.hoopTol) or "-",
            meta.hoopTolAt and ("%.2f"):format(meta.hoopTolAt) or "-"))
  do
    local t = {}
    for k, e in pairs(HUB.gs or {}) do t[#t+1] = { k = k, e = e } end
    table.sort(t, function(a, b) return a.e.n > b.e.n end)
    local parts = {}
    for i = 1, math.min(#t, 8) do
      local e = t[i].e
      if e.lo then
        parts[#parts+1] = ("%s x%d [%.1f..%.1f]"):format(t[i].k, e.n, e.lo, e.hi)
      else
        parts[#parts+1] = ("%s x%d"):format(t[i].k, e.n)
      end
    end
    rep(("[PB] intercept funnel: %s"):format(#parts > 0 and table.concat(parts, " | ") or "no data"))
  end

  do
    local t = {}
    for k, n in pairs(HUB.trajFunnel or {}) do t[#t+1] = { k = k, n = n } end
    table.sort(t, function(a, b) return a.n > b.n end)
    local parts = {}
    for i = 1, math.min(#t, 8) do parts[#parts+1] = ("%s x%d"):format(t[i].k, t[i].n) end
    rep(("[PB] trajectory funnel: %s"):format(#parts > 0 and table.concat(parts, " | ") or "no data"))
  end
  rep(("[PB] anti contest: %s | dodge before shot: %s (max %.0f stds)")
    :format(tostring(meta.antiShot or "no shot yet"),
            tostring(meta.antiPreShot), CFG.AntiDef.MaxShift))
  rep(("[PB] vertical: reach %.1f stds = apex %s + arms %.1f | in match: %s (gate %s)")
    :format(meta.reachY or -1,
            meta.jumpApex and ("%.1f measured x%d"):format(meta.jumpApex, meta.jumpApexN or 0)
              or "not measured yet (estimate)",
            CFG.Grab.ArmReach, tostring(meta.inMatch), tostring(meta.onlyInMatch)))
  rep(("[PB] stance: Auto Defense holdG=%s | Auto Move stance=%s (enabled %s, steal %s)")
    :format(tostring(meta.holdG), tostring(meta.autoStance),
            tostring(meta.m2Stance), tostring(meta.m2Steal)))
  rep(("[PB] prediction error at %.2fs ahead: avg=%.2f max=%.2f stds (n=%d)")
    :format(meta.predCheckAt or 0,
            meta.predFitAvg or -1, meta.predFitMax or -1, meta.predFitN))
  rep(("[PB] same, converged fit only (>=8 points): avg=%.2f max=%.2f stds (n=%d)")
    :format(meta.pred8Avg or -1, meta.pred8Max or -1, meta.pred8N or 0))

  rep(("[PB] free flight only (no dribble): avg=%.2f max=%.2f stds (n=%d)")
    :format(meta.predShotAvg or -1, meta.predShotMax or -1, meta.predShotN or 0))
  do

    local jl = meta.jumpLog or {}
    if #jl == 0 then
      rep("[PB] jump timing: no intercept jumps recorded yet")
    else
      local s, n, got = 0, 0, 0
      for _, e in ipairs(jl) do
        s += e.arrErr or 0; n += 1
        if e.reached then got += 1 end
      end
      rep(("[PB] jump timing: %d jumps, hands reached the ball on %d of them")
        :format(n, got))
      rep(("[PB]   ball arrived %+.0f ms vs predicted on average (plus = we jumped early)")
        :format(s / math.max(n, 1)))
      rep(("[PB]   reach model says %.1f stds = apex %.2f + arms %.1f")
        :format(JP.reachY(), HUB.jumpApex or -1, CFG.Grab.ArmReach))
      for _, e in ipairs(jl) do
        rep(("[PB]   %s dy %s (needed %s up) | arrErr %+d ms | lead %d ms | traj err %s | ping %d ms")
          :format(e.reached and "REACHED" or "missed ", tostring(e.dy),
                  tostring(e.needRise), e.arrErr or 0, e.wantLead or 0,
                  tostring(e.predErr), e.ping or 0))
      end
    end
  end
  rep(("[PB] foreign filtered: reg=%d green=%d feed=%d")
    :format(HUB.foreign.reg, HUB.foreign.green, HUB.foreign.feed))

  local ok, dump = pcall(function()
    return '{"meta":'..enc(meta,6)..',"report":'..enc(REPORT,2)
           ..',"log":'..enc(LOG,2)..',"shots":'..enc(HUB.shots,5)..'}'
  end)
  if not ok then return notify("serialize failed: "..tostring(dump)) end

  local path = CFG.Debug.File
  pcall(function()
    if makefolder and CFG.Debug.Folder and CFG.Debug.Folder ~= "" then
      if not (isfolder and isfolder(CFG.Debug.Folder)) then makefolder(CFG.Debug.Folder) end
      path = CFG.Debug.Folder .. "/" .. CFG.Debug.File
    end
  end)
  local wrote = false
  pcall(function() writefile(path, dump); wrote = true end)

  local copied = false
  if CFG.Debug.Copy then pcall(function() setclipboard(dump); copied = true end) end
  local tot=0; for _,v in pairs(HUB.stats) do tot+=v end
  HUB.lastDumpPath = path
  notify(("dump: %d shots, Perfect %d/%d -> %s%s")
    :format(HUB.shotsTotal or #HUB.shots, HUB.stats["Perfect"] or 0, tot,
            wrote and path or "WRITE FAILED",
            copied and " (copied)" or ""))

end

local VelHooked = {}

local function velOf(self)

  local mv = rawget(self, "MovementVelocity")
  if mv then return mv, self end
  local m = rawget(self, "Movement")
  if m then return rawget(m, "MovementVelocity"), m end
  return nil, nil
end

local function baseSpeedNoPenalty()
  local ws = sAttr(chr(), "WalkSpeed")
  ws = (type(ws) == "number") and math.min(ws, 14) or 14
  local sprinting = sAttr(chr(), "Sprinting") == true
  local st = sAttr(chr(), "Stamina")
  if sprinting and ((type(st) ~= "number") or st > 0.25) then
    ws = ws + (CFG.Move.Sprint.Enabled and CFG.Move.Sprint.Bonus or 3.35)
  end

  local S = CFG.Move.Strafe
  if S.Enabled then
    local m = HUB.mov
    if m then
      local fwd = rawget(m, "forwardValue")
      local dir = rawget(m, "MoveDirection")
      local root = rawget(m, "Root")
      if (not S.Side) and typeof(dir) == "Vector3" and root then
        local okc, cf = pcall(RDR.CFrame, root)
        if okc and cf and dir.Magnitude > 0.05 then
          ws = ws + (cf.LookVector:Dot(dir.Unit) - 1) * 2
        end
      end
      if (not S.Back) and type(fwd) == "number" then
        if fwd < 0.5 then ws = ws / 1.35 elseif fwd < 0.75 then ws = ws / 1.25 end
      end
    end
  end
  return ws
end

local function presetMul()
  local P = CFG.Move.Preset
  if not P.Enabled then return 1 end
  if P.FlattenAll then return 1 / 1 end
  local m = HUB.mov
  local t = m and rawget(m, "CurrentMovementType")
  local mul = t and P.Mul[t]
  return mul or 1
end

local function presetTurn()
  local P = CFG.Move.Preset
  if not P.Enabled then return 0 end
  local m = HUB.mov
  local t = m and rawget(m, "CurrentMovementType")
  return (t and P.Turn[t]) or 0
end

local function installVelHook()
  if next(VelHooked) then return true end
  if not (filtergc and hookfunction) then HUB.velSrc = "no filtergc/hookfunction"; return false end
  local ok, list = pcall(filtergc, "function", { Name = "UpdateVelocity" }, false)
  if not (ok and type(list) == "table") then HUB.velSrc = "UpdateVelocity not found"; return false end
  local n = 0
  for _, fn in ipairs(list) do
    if type(fn) == "function" and not VelHooked[fn] then
      local orig
      local okh = pcall(function()
        orig = hookfunction(fn, function(self, dt)
          local r = orig(self, dt)
          pcall(function()
            local mv, m = velOf(self)
            if not (mv and m) then return end
            if rawget(m, "WalkSpring") == nil then return end
            local M = CFG.Move
            local cur = mv.Velocity

            if M.Fly.Enabled and HUB.flyVec then
              mv.Velocity = HUB.flyVec
              return
            end

            -- ЗАМОРОЗКА, ИЗ КОТОРОЙ ИГРА НЕ ВЫХОДИТ САМА.
            -- Base_ModuleScript:236: при CanMove=false и Action="Moving" с
            -- ForceMoveDirection = (0,0,0) вся ветка обновления скорости
            -- заканчивается ранним return, а лерп к ServerVelocity выполняется
            -- ТОЛЬКО если та задана. В дампе ServerVelocity = nil, и скорость
            -- не трогается вообще: игрок стоит намертво (в журнале 45 секунд).
            -- Игра нас отсюда не вытащит — значит скорость пишем сами.
            local antiOn = HUB.antiSpeed and os.clock() < (HUB.antiSpeedUntil or 0)

            local cm = sAttr(chr(), "CanMove")
            local act = (cm == false) and sAttr(chr(), "Action") or nil
            -- SHOOTING STRAFE: движение во время УЖЕ ОТПУЩЕННОГО броска.
            -- На броске сервер ставит CanMove = false, и Base:236 выходит
            -- ранним return, не тронув скорость: игрок прибит к месту всю
            -- анимацию. Пока удар ДЕРЖАТ, лезть туда нельзя — ввод отменяет
            -- бросок. После релиза отменять уже нечего, поэтому окно
            -- открывается по ReleasedShot.
            local shootMove = false
            if cm == false and act == "Shooting" then
              local S = CFG.Move.Strafe
              shootMove = S.Enabled and S.Shooting
                          and sAttr(chr(), "ReleasedShot") ~= false
              if shootMove then HUB.shootStrafeAt = os.clock() end
            end
            -- УСЛОВИЕ ЗАМОРОЗКИ БЫЛО СЛИШКОМ УЗКИМ.
            -- Требовался ServerVelocity == nil, но в дампе он приходит как
            -- ВЕКТОР (0,0,0): Base:238 тогда лерпит скорость к нулю и всё
            -- равно выходит ранним return. Игрок так же прибит, а наш
            -- спасатель не срабатывал. Повторяем условие самой игры из
            -- Base:236: CanMove=false, Action="Moving" и ForceMoveDirection
            -- пуст или нулевой — из такого состояния игра сама не выходит.
            -- Ждём четверть секунды: короткие законные остановки (экран, фол,
            -- вбрасывание) успевают закончиться сами, застревание — нет.
            local frozen = false
            -- В ПРЫЖКЕ НЕ ВМЕШИВАЕМСЯ, И ЭТО ВАЖНЕЕ ВСЕЙ ОСТАЛЬНОЙ РАЗМОРОЗКИ.
            -- В дампе прыжка: Action="Moving", CanMove=false, ServerVelocity и
            -- ForceMoveDirection нулевые — то есть моё условие совпадает
            -- полностью, и на КАЖДОМ прыжке перехвата мы начинали писать
            -- горизонтальную скорость поверх прыжковой физики. Отсюда
            -- unfroze = 23057 за сессию и ощущение "не прыжок, а лаг".
            if cm == false and act == "Moving"
               and sAttr(chr(), "Stunned") ~= true
               and sAttr(chr(), "InAir") ~= true then
              local sv  = sAttr(chr(), "ServerVelocity")
              local fmd = sAttr(chr(), "ForceMoveDirection")
              local parked  = (sv == nil)
                or (typeof(sv) == "Vector3" and sv.Magnitude < 0.05)
              local noForce = (fmd == nil)
                or (typeof(fmd) == "Vector3" and fmd.Magnitude < 0.05)
              if parked and noForce then
                HUB.frozenSince = HUB.frozenSince or os.clock()
                frozen = (os.clock() - HUB.frozenSince) > 0.25
              else
                HUB.frozenSince = nil
              end
            else
              HUB.frozenSince = nil
            end
            if frozen then
              HUB.unfroze = (HUB.unfroze or 0) + 1
              HUB.unfrozeAt = os.clock()
            elseif cm == false and not (antiOn or shootMove) then
              -- ПОЧЕМУ ОТШАГ ЗДЕСЬ ЖИВЁТ, А ВСЁ ОСТАЛЬНОЕ НЕТ.
              -- Бросок — это core action: сервер ставит CanMove=false, и
              -- Base:236 выходит ранним return, не тронув скорость. Отшаг
              -- по замыслу идёт ИМЕННО во время броска, поэтому раньше он
              -- не двигал нас вообще — те самые «2-3 студа» были остатком
              -- инерции. Пропускаем только окно отшага, всё прочее как было.
              return
            end

            local inp = rawget(m, "MoveDirection")
            if antiOn and typeof(HUB.antiDir) == "Vector3" and HUB.antiDir.Magnitude > 0.1 then
              -- Movement:238 при CanMove=false подменяет MoveDirection на
              -- CFMoveDirection. Своё направление берём из отшага.
              inp = HUB.antiDir
            elseif shootMove or frozen then
              -- ЗДЕСЬ БЫЛА ЗАМКНУТАЯ ПЕТЛЯ, И ОНА ВЕЗЛА ИГРОКА САМА.
              -- Тот же корень ломал и разморозку: в заморозке скорость нулевая,
              -- значит CFMoveDirection тоже ноль, и функция выходила раньше
              -- записи. Счётчик unfroze рос (в дампе 13), а игрок стоял.
              -- MoveDirection на броске брать НЕЛЬЗЯ ни при каком значении:
              -- Movement:238 подставляет туда CFMoveDirection, а тот собран
              -- (Movement:149-163) из ТЕКУЩЕЙ скорости корня, а не из ввода.
              -- Мы писали скорость -> игра показывала её же как «направление»
              -- -> мы писали снова. Персонажа несло всю анимацию броска,
              -- причём в ту сторону, куда он двигался в момент нажатия.
              -- Сырой ввод цел в lastMoveDirection (Movement:184, до ветки
              -- CanMove) — только его и берём.
              local raw = rawget(m, "lastMoveDirection")
              if typeof(raw) == "Vector3" and raw.Magnitude > 0.1 then
                inp = raw
              else
                -- Клавиш нет. Просто выйти нельзя: MovementVelocity — силовой
                -- объект, без новой записи он продолжит толкать последним
                -- значением, а игровая ветка при CanMove=false до него не
                -- доходит. Гасим горизонталь явно, иначе «остановился, а меня
                -- ещё пару секунд везёт».
                mv.Velocity = Vector3.new(0, cur.Y, 0)
                return
              end
            end
            if typeof(inp) ~= "Vector3" or inp.Magnitude < 0.1 then return end
            local flatCur = Vector3.new(cur.X, 0, cur.Z)
            -- ОТШАГ AntiDefense СТАРТУЕТ С МЕСТА, И ЖДАТЬ РАЗГОН НЕЛЬЗЯ.
            -- Гейт «скорость меньше 1 — не трогаем» пропускал ровно тот момент,
            -- когда отшаг и начинается: игровая пружина WalkSpring разгоняется
            -- сама, и за время отшага мы уезжали меньше чем на студ. Пока
            -- идёт отшаг, гейт снимаем и задаём скорость с первого же кадра.
            if not (antiOn or frozen or shootMove) and flatCur.Magnitude < 1.0 then return end
            local want

            if frozen then
              want = M.Speed.Enabled and M.Speed.Value or baseSpeedNoPenalty()
            elseif antiOn then
              want = HUB.antiSpeed
            elseif shootMove then
              -- На броске скорость всегда наша: игровая ветка сюда не дошла.
              want = M.Speed.Enabled and M.Speed.Value or baseSpeedNoPenalty()
            elseif M.Speed.Enabled then want = M.Speed.Value
            elseif M.Strafe.Enabled or M.Sprint.Enabled or M.Preset.Enabled then
              want = baseSpeedNoPenalty()
            end
            if not want then return end
            want = want * presetMul()
            -- ПРО ПОТОЛОК 27.5 ИЗ Base:240/:248 — ОН НАС НЕ КАСАЕТСЯ.
            -- Игра обнуляет скорость выше 27.5, но делает это ВНУТРИ своей
            -- UpdateVelocity, а наш хук пишет Velocity уже ПОСЛЕ её возврата.
            -- Перезапись не проверяется повторно, поэтому кламп здесь только
            -- срезал бы Speed без всякой пользы.

            local tr = presetTurn()
            if tr > 0 then
              local ld = rawget(self, "LerpedDirection")
              local want2 = rawget(m, "MoveDirection")
              if typeof(ld) == "Vector3" and typeof(want2) == "Vector3"
                 and want2.Magnitude > 0.05 then
                pcall(function()
                  self.LerpedDirection = ld:Lerp(want2.Unit, math.clamp(dt * tr, 0, 1))
                end)
              end
            end
            local dirV = (inp.Magnitude > 0.1) and inp.Unit
                          or ((flatCur.Magnitude > 0.05) and flatCur.Unit or nil)
            if not dirV then return end
            mv.Velocity = dirV * want + Vector3.new(0, cur.Y, 0)
          end)
          return r
        end)
      end)
      if okh and orig then VelHooked[fn] = orig; n += 1 end
    end
  end
  HUB.velHooks = n
  HUB.velSrc = ("UpdateVelocity x%d"):format(n)
  return n > 0
end

local function removeVelHook()
  for fn, _ in pairs(VelHooked) do
    if restorefunction then pcall(restorefunction, fn) end
  end
  VelHooked = {}
  HUB.velHooks = 0
end
track({ Disconnect = removeVelHook })

local function moveEngineOn()
  installVelHook()
  findMovement()
  return HUB.velHooks and HUB.velHooks > 0
end

-- Слабые ключи: таблицы индексируются деталями персонажей, а те исчезают при
-- респавне. Без этого запись держала бы мёртвую деталь до конца сессии.
local clipSaved = weakKeys({})
local foeClipSaved = weakKeys({})
-- Список деталей на персонажа: дерево обходим редко, флаг ставим часто.
PBX.ghostCache = weakKeys({})
-- Кого мы пометили как несталкивающегося: вернуть при выключении.
local ghostAttr = weakKeys({})
local function ghostRestore()
  for part, was in pairs(foeClipSaved) do
    pcall(function() if part.Parent then part.CanCollide = was end end)
  end
  table.clear(foeClipSaved)
  for c in pairs(ghostAttr) do
    pcall(function() if c.Parent then c:SetAttribute("CanCollide", true) end end)
  end
  table.clear(ghostAttr)
end
track({ Disconnect = ghostRestore })
track(RunService.Heartbeat:Connect(function()
  if not (HUB.running and CFG.Move.GhostFoes.Enabled) then
    if next(foeClipSaved) then ghostRestore() end
    return
  end
  -- ЭТО ЧИСТЫЙ NOCLIP ПО ДЕТАЛЯМ, И ОН ОБЯЗАН РАБОТАТЬ КАЖДЫЙ КАДР.
  -- В прошлой версии я урезал его до четырёх раз в секунду, решив, что снятый
  -- CanCollide сам обратно не включается. Это оказалось неверно: между
  -- применениями коллизия успевала вернуться, и сквозь игрока было не пройти.
  -- Дорогим был не сам сброс, а обход дерева: GetDescendants строит новую
  -- таблицу на каждого. Дерево обходим раз в секунду и кэшируем, а флаг
  -- ставим каждый кадр по готовому списку — это просто запись свойства.
  local n = 0
  local now = os.clock()
  local rescan = (now - (HUB.ghostScanAt or 0)) > 1.0
  if rescan then HUB.ghostScanAt = now end
  -- Врезаться можно только в того, кто РЯДОМ. Список уже отфильтрован по
  -- 140 студам, но для коллизии и это далеко: держим свой, маленький радиус,
  -- иначе в парке каждый кадр перебираются десятки лишних персонажей.
  local mePos = selfPos()
  local gr = CFG.Move.GhostFoes.Radius
  for _, c in ipairs(charsList()) do
    local near = true
    if mePos and gr and gr > 0 then
      local q = posOf(sChild(c, "HumanoidRootPart"))
      near = q ~= nil and ((q - mePos) * FLAT).Magnitude <= gr
    end
    if near and ((CFG.Move.GhostFoes.All and c ~= chr()) or isEnemy(c)) then
      local list = PBX.ghostCache[c]
      if rescan or not list then
        list = {}
        local okd, kids = pcall(Mt.GetDescendants, c)
        if okd then
          for _, d in ipairs(kids) do
            if d:IsA("BasePart") then list[#list+1] = d end
          end
        end
        PBX.ghostCache[c] = list
      end
      -- ДВА РАЗНЫХ МЕХАНИЗМА СТОЛКНОВЕНИЯ, И СНИМАТЬ НАДО ОБА.
      -- 1) Физика движка: свойство CanCollide у деталей — это мы делали.
      -- 2) Collision_ModuleScript:114 ДОПОЛНИТЕЛЬНО расталкивает вручную,
      --    сдвигая HumanoidRootPart, и гейтится на АТРИБУТЕ CanCollide
      --    ПЕРСОНАЖА, а не на свойстве деталей. Снятое свойство его не
      --    останавливало вовсе — отсюда "проходить сквозь так и не даёт".
      --    Ставим атрибут локально: модуль сразу пропускает этого игрока.
      --    Свой атрибут по-прежнему НЕ трогаем, он реплицируется и вешает.
      pcall(function()
        if c:GetAttribute("CanCollide") ~= false then
          if ghostAttr[c] == nil then ghostAttr[c] = true end
          c:SetAttribute("CanCollide", false)
        end
      end)
      local okw = pcall(function()
        for i = 1, #list do
          local d = list[i]
          if d.Parent then
            if foeClipSaved[d] == nil then foeClipSaved[d] = true end
            d.CanCollide = false
            n += 1
          end
        end
      end)
      if not okw then PBX.ghostCache[c] = nil end
    end
  end
  HUB.ghostParts = n
end))
local function noclipRestore()
  for part, was in pairs(clipSaved) do
    pcall(function() if part.Parent then part.CanCollide = was end end)
  end
  table.clear(clipSaved)
end
track({ Disconnect = noclipRestore })

track(RunService.Heartbeat:Connect(function()
  if not (HUB.running and CFG.Move.NoClip.Enabled) then
    if next(clipSaved) then noclipRestore() end
    return
  end
  local pc = proxyPart(); if not pc then return end
  -- ЕДИНСТВЕННЫЙ БЕЗУСЛОВНЫЙ ОБХОД ДЕРЕВА В КАДРОВОМ ПУТИ.
  -- GetDescendants строил новую таблицу каждый кадр. Состав деталей у
  -- персонажа не меняется, поэтому обходим раз в секунду и кэшируем.
  local now = os.clock()
  local list = HUB.noclipList
  if pc ~= HUB.noclipFor or not list or (now - (HUB.noclipAt or 0)) > 1.0 then
    HUB.noclipAt, HUB.noclipFor = now, pc
    list = { pc }
    local okd, kids = pcall(Mt.GetDescendants, pc)
    if okd then
      for _, d in ipairs(kids) do
        if d:IsA("BasePart") then list[#list+1] = d end
      end
    end
    HUB.noclipList = list
  end
  for _, part in ipairs(list) do
    local okc, cc = pcall(RDR.CanCollide, part)
    if okc and cc then
      if clipSaved[part] == nil then clipSaved[part] = true end
      pcall(PBX.setCC, part, false)
    end
  end
  HUB.noclipParts = #list
end))

track(RunService.Heartbeat:Connect(function(dt)
  local M = CFG.Move
  if not (HUB.running and M.Fly.Enabled) then
    HUB.flyVec, HUB.flyPos = nil, nil
    return
  end
  local pc = proxyPart(); if not pc then return end
  local cam = Workspace.CurrentCamera; if not cam then return end
  local okc, cf = pcall(RDR.CFrame, pc); if not (okc and cf) then return end
  HUB.flyPos = HUB.flyPos or cf.Position

  local mv = Vector3.new()
  local ok2 = pcall(function()
    local look  = cam.CFrame.LookVector * FLAT
    local right = cam.CFrame.RightVector * FLAT
    if look.Magnitude  > 0.01 then look  = look.Unit  end
    if right.Magnitude > 0.01 then right = right.Unit end
    if UIS:IsKeyDown(Enum.KeyCode.W) then mv += look end
    if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= look end
    if UIS:IsKeyDown(Enum.KeyCode.D) then mv += right end
    if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= right end
    if UIS:IsKeyDown(Enum.KeyCode.Space)     then mv += Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.new(0,1,0) end
  end)
  if not ok2 then return end
  if mv.Magnitude > 0.01 then mv = mv.Unit * M.Fly.Speed else mv = Vector3.new() end
  HUB.flyVec = mv
  HUB.flyPos = HUB.flyPos + mv * dt

  tpProxy(pc, (cf - cf.Position) + HUB.flyPos)
end))

track(RunService.Heartbeat:Connect(function()

  if not (HUB.running and CFG.Move.AutoSprint.Enabled) then
    if HUB.sprintAuto then
      HUB.sprintAuto = false
      HUB.bypass = true
      pcall(Mt.FireServer, R.Sprint, false)
      HUB.bypass = false
    end
    return
  end
  if HUB.steering then return end

  if CFG.Zero.Enabled and CFG.Zero.KillSprint and os.clock() < zeroUntil then
    if HUB.sprintAuto then
      HUB.sprintAuto = false
      HUB.bypass = true
      pcall(Mt.FireServer, R.Sprint, false)
      HUB.bypass = false
    end
    return
  end
  local m = HUB.mov or findMovement()
  local moving = false
  if m then
    local ok, d = pcall(RDR.MoveDirection, m)
    moving = ok and typeof(d) == "Vector3" and d.Magnitude > 0.1
    -- ВО ВРЕМЯ БРОСКА MoveDirection ОБНУЛЁН ИГРОЙ (Movement:238), и авто-спринт
    -- честно видел «стоим» и выключался ровно тогда, когда он нужен. При
    -- включённом Shooting Strafe смотрим на сырой ввод игрока.
    if not moving then
      local S = CFG.Move.Strafe
      if S.Enabled and S.Shooting and sAttr(chr(), "Action") == "Shooting"
         and sAttr(chr(), "ReleasedShot") ~= false then
        local okr, raw = pcall(RDR.lastMoveDirection, m)
        moving = okr and typeof(raw) == "Vector3" and raw.Magnitude > 0.1
      end
    end
  end
  local st = sAttr(chr(), "Stamina")
  local can = (type(st) ~= "number") or st > 20
  local want = moving and can
  if want ~= (HUB.sprintAuto == true) then
    HUB.sprintAuto = want
    HUB.bypass = true
    pcall(Mt.FireServer, R.Sprint, want)
    HUB.bypass = false
  end
end))

track(RunService.Heartbeat:Connect(function()
  if not HUB.running then return end
  local c = chr(); if not c then return end
  if CFG.Move.NoStun.Enabled then
    pcall(function()
      c:SetAttribute("Stunned", false)
      c:SetAttribute("CanMove", true)
      c:SetAttribute("CanTurn", true)
    end)
  end
  if CFG.Move.NoCooldown.Enabled then
    pcall(function() c:SetAttribute("Debounce", false) end)
  end
end))

local GAME_MOVES = {
  { id = "Z",      Name = "Move Z",    key = Enum.KeyCode.Z, combo = "Z" },
  { id = "X",      Name = "Move X",    key = Enum.KeyCode.X, combo = "X" },
  { id = "C",      Name = "Move C",    key = Enum.KeyCode.C, combo = "C" },
  { id = "V",      Name = "Move V",    key = Enum.KeyCode.V, combo = "V" },
  { id = "H",      Name = "Dribble H", key = Enum.KeyCode.H, rem = "Dribble", arg = "H" },
  { id = "Steal",  Name = "Steal",     key = Enum.KeyCode.R, rem = "Steal" },
  { id = "Screen", Name = "Screen",    key = Enum.KeyCode.T, rem = "Screen",
    hold = true, on = true, off = false },
  { id = "Clutch", Name = "Clutch",    key = Enum.KeyCode.Q, rem = "Clutch" },
  { id = "HoldG",  Name = "Hold G",    key = Enum.KeyCode.G, rem = "HoldG",
    hold = true, on = { HoldingG = true }, off = { HoldingG = false } },
}

for _, m in ipairs(GAME_MOVES) do CFG.Move.Moves.Bind[m.id] = m.key end

local kbCtrl, kbComp, kbSrc = nil, nil, nil
local function findInput()
  if kbCtrl and rawget(kbCtrl, "KeyDown") ~= nil then return end
  if not filtergc then kbSrc = "no filtergc"; return end

  local ok, fn = pcall(filtergc, "function", { Name = "AddToCombo" }, true)
  if ok and type(fn) == "function" then
    HUB.addCombo = fn
    local ok2, ups = pcall(debug.getupvalues, fn)
    if ok2 and type(ups) == "table" then
      for _, v in pairs(ups) do
        if type(v) == "table" then
          if rawget(v, "KeyDown") ~= nil and rawget(v, "KeyUp") ~= nil then
            kbCtrl, kbSrc = v, "upvalue AddToCombo"
          elseif rawget(v, "Character") ~= nil and rawget(v, "ProfileData") ~= nil then
            HUB.playerCtrl = v
          end
        end
      end
    end
  end

  if not kbComp then
    local ok3, t = pcall(filtergc, "table",
      { Keys = { "AddToCombo", "AddToTap", "Combo", "Tap" } }, true)
    if ok3 and type(t) == "table" then kbComp = t end
  end
  if not kbComp then
    local ok3b, t = pcall(filtergc, "table",
      { Keys = { "Keyboard", "Gamepad", "Mobile", "Loaded" } }, true)
    if ok3b and type(t) == "table" then
      local k = rawget(t, "Keyboard")
      if type(k) == "table" and rawget(k, "AddToCombo") ~= nil then kbComp = k end
    end
  end

  if not kbCtrl then
    local ok4, t = pcall(filtergc, "table",
      { Keys = { "KeyDown", "KeyUp", "AreAllDown", "AreAnyDown" } }, true)
    if ok4 and type(t) == "table" then kbCtrl, kbSrc = t, "table keys" end
  end
  if not kbCtrl then kbSrc = kbComp and "direct path only" or "not found" end
end

local keySwallow, keyMine = {}, {}
local origDownFire, origUpFire = nil, nil
local movesHooked, movesListening = false, false

local function rebuildMoveMap()
  table.clear(keySwallow); table.clear(keyMine)
  local B = CFG.Move.Moves.Bind
  for _, m in ipairs(GAME_MOVES) do
    local b = B[m.id]
    if b ~= nil and b ~= m.key then
      local list = keyMine[b]
      if not list then list = {}; keyMine[b] = list end
      list[#list+1] = m
      keySwallow[m.key] = true
    end
  end
end

local function viaSignal(sigName, key)
  if not kbCtrl then return false end
  local sig = rawget(kbCtrl, sigName); if type(sig) ~= "table" then return false end
  local f = (sigName == "KeyDown") and origDownFire or origUpFire
  if type(f) ~= "function" then f = rawget(getmetatable(sig) or {}, "Fire") end
  if type(f) ~= "function" then return false end
  local ok = pcall(f, sig, key)
  return ok
end

local function viaDirect(m, down)
  if m.combo then

    if type(HUB.addCombo) == "function" and kbComp then
      return pcall(HUB.addCombo, kbComp, m.combo)
    end

    local r = InputSvc:FindFirstChild("Dribble"); if not r then return false end
    local sprint = false
    pcall(function() sprint = UIS:IsKeyDown(Enum.KeyCode.LeftShift) end)
    local dir = Vector3.new()
    local mv = HUB.mov or (HUB.playerCtrl and rawget(HUB.playerCtrl, "Character")
                           and rawget(rawget(HUB.playerCtrl, "Character"), "Movement"))
    if type(mv) == "table" then
      local d = rawget(mv, "lastMoveDirection")
      if typeof(d) == "Vector3" then dir = d end
    end
    HUB.bypass = true
    local ok = pcall(Mt.FireServer, r, m.combo, sprint, dir)
    HUB.bypass = false
    return ok
  end
  local r = InputSvc:FindFirstChild(m.rem); if not r then return false end
  local payload = m.arg
  if m.hold then payload = down and m.on or m.off end
  HUB.bypass = true
  local ok
  if payload == nil then ok = pcall(Mt.FireServer, r)
  else                   ok = pcall(Mt.FireServer, r, payload) end
  HUB.bypass = false
  return ok
end

local function sendMove(m, down)
  findInput()
  if viaSignal(down and "KeyDown" or "KeyUp", m.key) then
    HUB.moveKeyPath = "signal"
    return
  end
  if viaDirect(m, down) then HUB.moveKeyPath = "direct"
  else HUB.moveKeyPath = "not delivered" end
end

PBX.DRIBBLE_KEY = { StepBack = "X", SnatchBack = "XX", Crossover = "Z",
                    BehindBack = "ZX", Spin = "ZXC", Hesitation = "C" }

local lastPress = {}
local function pressMove(m)
  if not (HUB.running and CFG.Move.Moves.Enabled) then return end
  local b = CFG.Move.Moves.Bind[m.id]

  if b == nil or b == m.key then return end
  local now = os.clock()
  if now - (lastPress[m.id] or 0) < 0.06 then return end
  lastPress[m.id] = now
  sendMove(m, true)
  if not m.hold then return end

  local held = false
  if typeof(b) == "EnumItem" and b.EnumType == Enum.KeyCode then
    pcall(function() held = UIS:IsKeyDown(b) end)
  end
  if not held then task.delay(0.3, function() sendMove(m, false) end) end
end

local function releaseMove(m)
  if not (HUB.running and CFG.Move.Moves.Enabled) then return end
  if not m.hold then return end
  local b = CFG.Move.Moves.Bind[m.id]
  if b == nil or b == m.key then return end
  sendMove(m, false)
end

local function keyIdOf(input)
  local k = input.KeyCode
  if k ~= nil and k ~= Enum.KeyCode.Unknown then return k end
  return input.UserInputType
end

local function installMoveKeys()
  findInput()

  if kbCtrl and not movesHooked then
    local dn, up = rawget(kbCtrl, "KeyDown"), rawget(kbCtrl, "KeyUp")
    if type(dn) == "table" and type(up) == "table" then
      local mt = getmetatable(dn)
      origDownFire = rawget(dn, "Fire") or (mt and rawget(mt, "Fire"))
      origUpFire   = rawget(up, "Fire") or (mt and rawget(mt, "Fire"))
      if type(origDownFire) == "function" and type(origUpFire) == "function" then
        local function guard(orig)
          return function(self, key, ...)
            if CFG.Move.Moves.Enabled and key ~= nil and keySwallow[key] then return end
            return orig(self, key, ...)
          end
        end
        rawset(dn, "Fire", guard(origDownFire))
        rawset(up, "Fire", guard(origUpFire))
        movesHooked = true
      end
    end
  end

  if not movesListening then
    movesListening = true
    track(UIS.InputBegan:Connect(function(input, gpe)
      if gpe then return end
      if UIS:GetFocusedTextBox() then return end
      local list = keyMine[keyIdOf(input)]; if not list then return end
      for _, m in ipairs(list) do pressMove(m) end
    end))

    track(UIS.InputEnded:Connect(function(input)
      local list = keyMine[keyIdOf(input)]; if not list then return end
      for _, m in ipairs(list) do releaseMove(m) end
    end))
  end
  HUB.moveKeyInfo = ("%s%s"):format(tostring(kbSrc or "?"),
                                    movesHooked and " + swallow" or " (no swallow)")
  return true
end

local function restoreMoveKeys()
  if not movesHooked then return end
  if kbCtrl then
    local dn, up = rawget(kbCtrl, "KeyDown"), rawget(kbCtrl, "KeyUp")
    if type(dn) == "table" then rawset(dn, "Fire", nil) end
    if type(up) == "table" then rawset(up, "Fire", nil) end
  end
  movesHooked = false
end

function HUB.unload()
  HUB.running = false; HUB.gen += 1
  pcall(function() local c = chr(); if c then c:SetAttribute("CFrame", nil) end end)
  hideAll()
  for _,l in pairs(lines) do if l then pcall(function() l:Remove() end) end end
  for _,m in pairs(marks) do if m then pcall(function() m:Remove() end) end end
  for _,c in ipairs(HUB.conns) do pcall(function() c:Disconnect() end) end
  pcall(restoreMoveKeys)
  if oldNamecall then pcall(function() hookmetamethod(game,"__namecall",oldNamecall) end) end
end
track(LP.CharacterAdded:Connect(function() HUB.myChar=nil; meterChar=nil end))

return function(_Lib, _Core)
  local M = {}

  function M.start()

    CFG.Enabled          = false
    CFG.Traj.Enabled     = false
    CFG.Grab.Enabled     = false
    CFG.Defense.Enabled  = false
    CFG.Blatant.Enabled  = false
    CFG.Spoof.Enabled    = false
    CFG.S3.Enabled       = false
    CFG.Stamina.Enabled  = false
    CFG.Move.Speed.Enabled      = false
    CFG.Move.Fly.Enabled        = false
    CFG.Move.Strafe.Enabled     = false
    CFG.Move.AutoSprint.Enabled = false
  end

  function M.buildUI(ctx)
    HUB.notify = ctx.notify
    local uiReady = false
    local function say(title, body)
      if uiReady then pcall(ctx.notify, title, body) end
    end

    local function feature(section, o)
      local guard, togEl = false, nil
      local function commit(val)
        val = val and true or false
        o.set(val)
        say(o.Title, val and "on" or "off")
        guard = true
        if togEl then pcall(function() togEl:UpdateState(val) end) end
        guard = false
      end
      section:Header({ Name = o.Title })
      togEl = section:Toggle({
        Name = "Enabled", Default = o.get(),
        Callback = function(v) if guard then return end commit(v) end,
      }, ctx.flag(o.Flag))
      if o.Desc then section:SubLabel({ Text = o.Desc }) end
      ctx.keybind(section, {
        Name   = "Keybind",
        Flag   = ctx.flag(o.Flag .. "_KB"),
        Toggle = function() commit(not o.get()) end
      })
      return { commit = commit, el = togEl }
    end

    local function bool(section, name, desc, get, set, flagName)
      local el = section:Toggle({
        Name = name, Default = get(),
        Callback = function(v) set(v and true or false); say(name, v and "on" or "off") end,
      }, ctx.flag((flagName or name:gsub("%s+","")) .. "_T"))
      if desc then section:SubLabel({ Text = desc }) end
      return el
    end

    local function slider(section, o)
      local el = section:Slider({
        Name = o.Name, Default = o.Default,
        Minimum = o.Min, Maximum = o.Max,
        Precision = o.Precision or 0, Suffix = o.Suffix,
        Callback = o.Callback,
      }, ctx.flag(o.Flag))
      -- Подпись держим при элементе: иначе спрятанный слайдер оставлял бы
      -- висеть свой пояснительный текст.
      if o.Desc then el._desc = section:SubLabel({ Text = o.Desc }) end
      return el
    end

    do
      local T = ctx.tabs.AutoGreen

      local s1 = T:Section({ Side = "Left" })
      feature(s1, {
        Title = "Auto Green", Flag = "AG_Enabled",
        get = function() return CFG.Enabled end,
        set = function(v) CFG.Enabled = v end
      })
      bool(s1, "Time Dunks",
        "dunks and layups get graded on timing too, but the ball has left your hands by then",
        function() return CFG.TimeDunks end,
        function(v) CFG.TimeDunks = v end, "AG_TimeDunks")

      s1:SubLabel({ Text = ("Target %.4f (Perfect centre measured 1.517)")
        :format(CFG.Target) })
      slider(s1, { Name = "Ping Factor", Flag = "AG_PingCoef", Default = CFG.PingCoef,
        Min = 0.50, Max = 1.30, Precision = 2,
        Callback = function(v) CFG.PingCoef = v end })
      bool(s1, "Measure Meter Speed", "read the real fill speed of each shot",
        function() return CFG.UseFittedRate end,
        function(v) CFG.UseFittedRate = v end)
      bool(s1, "Log Verdicts", nil,
        function() return CFG.Debug.Verdict end,
        function(v) CFG.Debug.Verdict = v end, "AG_Verdict")

      local s2 = T:Section({ Side = "Right" })
      feature(s2, {
        Title = "Distance Spoof", Flag = "SP_Enabled",
        get = function() return CFG.Spoof.Enabled end,
        set = function(v) CFG.Spoof.Enabled = v end
      })
      s2:SubLabel({ Text = "stands you somewhere else only while the shot registers" })
      slider(s2, { Name = "Shoot From", Flag = "SP_Fake", Default = CFG.Spoof.FakeDist,
        Min = 5, Max = 25, Suffix = " stds",
        Callback = function(v) CFG.Spoof.FakeDist = v end,
        Desc = "the distance the server sees, counted from the hoop" })
      slider(s2, { Name = "Skip Closer Than", Flag = "SP_MinReal", Default = CFG.Spoof.MinRealDist,
        Min = 10, Max = 60, Suffix = " stds",
        Callback = function(v) CFG.Spoof.MinRealDist = v end,
        Desc = "shots nearer than this are left alone, the arc sits at 23.5" })
      slider(s2, { Name = "Lead Time", Flag = "SP_PreTime", Default = CFG.Spoof.PreTime,
        Min = 0.008, Max = 0.15, Precision = 3, Suffix = " s",
        Callback = function(v) CFG.Spoof.PreTime = v end,
        Desc = "how early you land there before the packet goes out" })
      slider(s2, { Name = "Register Wait", Flag = "SP_HoldMax", Default = CFG.Spoof.HoldMax,
        Min = 0.05, Max = 0.6, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Spoof.HoldMax = v end,
        Desc = "give up holding the fake spot after this long" })
      bool(s2, "Wait For Register", "come back only once the server took the shot",
        function() return CFG.Spoof.HoldUntilRegister end,
        function(v) CFG.Spoof.HoldUntilRegister = v end)
      bool(s2, "Keep The 3", "never pull you inside the arc, that would cost a point",
        function() return CFG.Spoof.KeepThree end,
        function(v) CFG.Spoof.KeepThree = v end, "SP_Keep3")

      local s2b = T:Section({ Side = "Right" })
      feature(s2b, {
        Title = "Smart 3PT", Flag = "S3_Enabled",
        get = function() return CFG.S3.Enabled end,
        set = function(v) CFG.S3.Enabled = v end
      })
      s2b:SubLabel({ Text = "on a two near the line, register the shot from behind it" })
      s2b:SubLabel({ Text = "works alone, and takes priority over Distance Spoof when both are on" })
      slider(s2b, { Name = "Line Distance", Flag = "S3_Line", Default = CFG.S3.LineDist,
        Min = 12, Max = 40, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.S3.LineDist = v end,
        Desc = "how far the arc sits from the hoop, the dump prints the measured one" })
      slider(s2b, { Name = "Reach", Flag = "S3_Win", Default = CFG.S3.Window,
        Min = 1, Max = 14, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.S3.Window = v end,
        Desc = "how far short of the line it will still pull you out" })
      slider(s2b, { Name = "Past The Line", Flag = "S3_Extra", Default = CFG.S3.Extra,
        Min = 0, Max = 5, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.S3.Extra = v end,
        Desc = "margin behind the arc, too small and the server still calls a 2" })
      bool(s2b, "Hold Until Score", "keep the fake spot until the ball resolves",
        function() return CFG.S3.Hold end,
        function(v) CFG.S3.Hold = v end, "S3_Hold")
      slider(s2b, { Name = "Score Wait", Flag = "S3_HoldMax", Default = CFG.S3.HoldMax,
        Min = 0.5, Max = 3.0, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.S3.HoldMax = v end,
        Desc = "the 2 or 3 call happens when the ball goes in, not on release" })

      s1:Divider()
      s1:Header({ Name = "Timing" })
      local s3 = s1
      slider(s3, { Name = "Meter Speed Min", Flag = "AG_RateLo", Default = CFG.RateLo,
        Min = 0.8, Max = 3.0, Precision = 2,
        Callback = function(v) CFG.RateLo = v end,
        Desc = "free throws fill at ~1.6, normal shots at ~3.1" })
      slider(s3, { Name = "Meter Speed Max", Flag = "AG_RateHi", Default = CFG.RateHi,
        Min = 3.0, Max = 6.0, Precision = 2,
        Callback = function(v) CFG.RateHi = v end })
      slider(s3, { Name = "Fallback Speed", Flag = "AG_RateFlat", Default = CFG.RateFlat,
        Min = 2.5, Max = 4.0, Precision = 2,
        Callback = function(v) CFG.RateFlat = v end })
      slider(s3, { Name = "Max Hold", Flag = "AG_MaxWait", Default = CFG.MaxWait,
        Min = 0.6, Max = 2.0, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.MaxWait = v end })
      slider(s3, { Name = "Arm Window", Flag = "AG_ArmWindow", Default = CFG.ArmWindow,
        Min = 0.2, Max = 1.5, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.ArmWindow = v end })
      slider(s3, { Name = "Spin Window", Flag = "AG_Spin", Default = CFG.SpinWindow,
        Min = 0.005, Max = 0.05, Precision = 3, Suffix = " s",
        Callback = function(v) CFG.SpinWindow = v end })

      local s6 = T:Section({ Side = "Right" })
      feature(s6, {
        Title = "Anti Defense", Flag = "AD_Enabled",
        get = function() return CFG.AntiDef.Enabled end,
        set = function(v) CFG.AntiDef.Enabled = v; if v then moveEngineOn() end end
      })
      s6:SubLabel({ Text = "contest builds up while a defender covers you" })
      local adShow
      bool(s6, "Dodge Before Shot",
        "break away between your press and the shot leaving",
        function() return CFG.AntiDef.PreShot end,
        function(v) CFG.AntiDef.PreShot = v end)
      s6:Dropdown({
        Name = "Dodge Mode", Options = { "Legit", "BackTP", "Teleport", "Permanent" },
        Default = CFG.AntiDef.Mode, Required = true,
        Callback = function(v)
          if type(v) ~= "string" then return end
          CFG.AntiDef.Mode = v
          if adShow then adShow(v) end
        end,
      }, ctx.flag("AD_Mode"))
      s6:SubLabel({ Text = "Legit walks | BackTP jumps back for real | Teleport fakes it | Permanent stays" })

      s6:Header({ Name = "When To Dodge" })
      slider(s6, { Name = "Start Within", Flag = "AD_React", Default = CFG.AntiDef.React,
        Min = 4, Max = 30, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.AntiDef.React = v end,
        Desc = "a defender closer than this counts as covering you" })
      slider(s6, { Name = "Stop At", Flag = "AD_StopAt", Default = CFG.AntiDef.StopAt,
        Min = 6, Max = 40, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.AntiDef.StopAt = v end,
        Desc = "this much room is enough, stop trying for more" })
      bool(s6, "Count Stance As Closer",
        "a defender holding G is the one that actually hurts, run from him first",
        function() return CFG.AntiDef.Stance end,
        function(v) CFG.AntiDef.Stance = v end, "AD_Stance")

      -- НАСТРОЙКИ РЕЖИМА ПОКАЗЫВАЮТСЯ ТОЛЬКО ДЛЯ ВЫБРАННОГО РЕЖИМА.
      -- Раньше на экране висели разом все четыре набора, и понять, какой из
      -- них сейчас что-то делает, было нельзя. Прячем через SetVisibility:
      -- элементы остаются во флагах и в конфиге, просто не мозолят глаза.
      local adLegit, adBack, adTele = {}, {}, {}
      s6:Header({ Name = "Mode Settings" })
      adLegit[#adLegit+1] = slider(s6, { Name = "Walk Time", Flag = "AD_StepTime",
        Default = CFG.AntiDef.StepTime, Min = 0.05, Max = 0.6, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.AntiDef.StepTime = v end,
        Desc = "how long you keep walking after the press" })
      adLegit[#adLegit+1] = slider(s6, { Name = "Walk Speed", Flag = "AD_Speed",
        Default = CFG.AntiDef.Speed, Min = 14, Max = 40, Suffix = " stds/s",
        Callback = function(v) CFG.AntiDef.Speed = v end,
        Desc = "written to velocity directly, the game itself caps you at 17" })

      adBack[#adBack+1] = slider(s6, { Name = "Jump Back", Flag = "AD_BackTP",
        Default = CFG.AntiDef.BackTPMax, Min = 3, Max = 25, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.AntiDef.BackTPMax = v end,
        Desc = "most it will move you in one step, still capped by Stop At" })

      adTele[#adTele+1] = slider(s6, { Name = "Jump Distance", Flag = "AD_Shift",
        Default = CFG.AntiDef.MaxShift, Min = 3, Max = 20, Suffix = " stds",
        Callback = function(v) CFG.AntiDef.MaxShift = v end,
        Desc = "how far sideways the faked position may sit" })

      s6:Header({ Name = "Dribble Escape" })
      bool(s6, "Use Dribble Move",
        "a step back move opens the gap without waiting for your feet",
        function() return CFG.AntiDef.Dribble end,
        function(v) CFG.AntiDef.Dribble = v end, "AD_Drib")
      s6:Dropdown({
        Name = "Move", Options = { "X", "XX", "Z", "C", "H" },
        Default = CFG.AntiDef.DribbleCombo, Required = true,
        Callback = function(v) if type(v) == "string" then CFG.AntiDef.DribbleCombo = v end end,
      }, ctx.flag("AD_DribCombo"))
      s6:SubLabel({ Text = "X step back | XX snatch back | Z C crossover | H switch hand" })
      slider(s6, { Name = "Cooldown", Flag = "AD_DribCD", Default = CFG.AntiDef.DribbleCD,
        Min = 0.3, Max = 4.0, Precision = 1, Suffix = " s",
        Callback = function(v) CFG.AntiDef.DribbleCD = v end })

      function adShow(mode)
        local function put(list, on)
          for _, el in ipairs(list) do
            if el and el.SetVisibility then pcall(el.SetVisibility, el, on) end
            local d = el and el._desc
            if d and d.SetVisibility then pcall(d.SetVisibility, d, on) end
          end
        end
        put(adLegit, mode == "Legit")
        put(adBack,  mode == "BackTP")
        put(adTele,  mode == "Teleport" or mode == "Permanent")
      end
      adShow(CFG.AntiDef.Mode)

      s6:Header({ Name = "Constant Push" })
      bool(s6, "Enable Constant Push",
        "bends your own course away from defenders ALL the time, off by default",
        function() return CFG.AntiDef.PushOn end,
        function(v) CFG.AntiDef.PushOn = v end, "AD_PushOn")
      slider(s6, { Name = "Push Within", Flag = "AD_Keep", Default = CFG.AntiDef.Keep,
        Min = 3, Max = 22, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.AntiDef.Keep = v end,
        Desc = "closer than this your course bends away, except near the hoop" })
      slider(s6, { Name = "Push Strength", Flag = "AD_Push", Default = CFG.AntiDef.Push,
        Min = 0.1, Max = 1.0, Precision = 2,
        Callback = function(v) CFG.AntiDef.Push = v end,
        Desc = "0.1 barely nudges, 1.0 fully overrides your input" })
      bool(s6, "Only With Ball", "leave your movement alone on defense",
        function() return CFG.AntiDef.OnlyBall end,
        function(v) CFG.AntiDef.OnlyBall = v end, "AD_OnlyBall")

      s6:Button({ Name = "Test Step (no shot)", Callback = function()
        task.spawn(function()
          local ok, res = pcall(PBX.antiTest)
          if not ok then notify("anti test failed: " .. tostring(res):sub(1, 60)) end
          if ok and setclipboard then pcall(setclipboard, res) end
        end)
      end }, ctx.flag("AD_Test_B"))

      local s5 = T:Section({ Side = "Left" })
      feature(s5, {
        Title = "Force Zero Spread", Flag = "ZS_Enabled",
        get = function() return CFG.Zero.Enabled end,
        set = function(v)
          CFG.Zero.Enabled = v
          if v then

            if CFG.Zero.Stand then moveEngineOn() end
          else
            zeroRelease()
          end
        end,
        Desc = "hides sprint and motion from the shot"
      })
      bool(s5, "Stand Still", "moving shots carry a spread penalty",
        function() return CFG.Zero.Stand end,
        function(v) CFG.Zero.Stand = v; if v then moveEngineOn() end end, "ZS_Stand")
      bool(s5, "Drop Sprint", "clear the sprint flag and the payload field",
        function() return CFG.Zero.KillSprint end,
        function(v) CFG.Zero.KillSprint = v end, "ZS_Sprint")
      bool(s5, "Whole Shot", "stand from the shot start, not only at release",
        function() return CFG.Zero.FromStart end,
        function(v) CFG.Zero.FromStart = v end, "ZS_FromStart")
      slider(s5, { Name = "Stand Before", Flag = "ZS_Lead", Default = CFG.Zero.Lead,
        Min = 0.05, Max = 0.6, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Zero.Lead = v end })
      slider(s5, { Name = "Stand After", Flag = "ZS_Tail", Default = CFG.Zero.Tail,
        Min = 0, Max = 0.4, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Zero.Tail = v end })

      s1:Divider()
      local s4 = s1
      s4:Header({ Name = "Last Shot" })
      local shotPara = s4:Paragraph({ Header = "Result", Body = "no shots yet" })
      task.spawn(function()
        while HUB.running do
          task.wait(0.5)
          pcall(function()
            local sh = HUB.lastShot
            if not sh then return end
            shotPara:UpdateBody(table.concat({
              ("verdict: %s"):format(tostring(sh.verdict or "waiting")),
              ("server meter: %.3f"):format(sh.srvMeter or 0),
              ("meter rate: %.2f (%s)"):format(sh.rateUsed or 0,
                sh.rateFitted and "measured" or "fallback"),
              ("green window: %.3f"):format(sh.greenWidth or 0),
              ("hold: %.0f ms, released by %s"):format((sh.hold or 0)*1000, tostring(sh.firedBy)),
              ("contest: %s"):format(tostring(sh.contest or "-")),
            }, "\n"))
          end)
        end
      end)
    end

    do
      local T = ctx.tabs.Defense

      local s1 = T:Section({ Side = "Left" })
      feature(s1, {
        Title = "Auto Defense", Flag = "DEF_Enabled",
        get = function() return CFG.Defense.Enabled end,
        set = function(v)
          CFG.Defense.Enabled = v
          if v then installMoveHook() else stopSteer("defense"); holdRelease() end
        end
      })
      s1:Dropdown({
        Name = "Mode", Options = { "Auto", "Hook" },
        Default = CFG.Defense.Mode, Required = true,
        Callback = function(v) if type(v) == "string" then CFG.Defense.Mode = v end end,
      }, ctx.flag("DEF_Mode"))
      s1:SubLabel({ Text = "Hook only redirects your own movement" })
      s1:Dropdown({
        Name = "Face", Options = { "Off", "Enemy", "Ball" },
        Default = CFG.Face.Mode, Required = true,
        Callback = function(v) if type(v) == "string" then CFG.Face.Mode = v end end,
      }, ctx.flag("DEF_FaceMode"))
      s1:SubLabel({ Text = "who you turn toward while guarding, also used by Auto Move" })
      slider(s1, { Name = "Turn Speed", Flag = "DEF_FaceRate", Default = CFG.Face.Rate,
        Min = 2, Max = 25, Precision = 1, Suffix = " rad/s",
        Callback = function(v) CFG.Face.Rate = v end })
      slider(s1, { Name = "Turn Smoothing", Flag = "DEF_FaceSmooth", Default = CFG.Face.Smooth,
        Min = 0.05, Max = 1, Precision = 2,
        Callback = function(v) CFG.Face.Smooth = v end })
      slider(s1, { Name = "Walk Around Him", Flag = "DEF_Around", Default = CFG.Defense.WalkAround,
        Min = 0, Max = 8, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Defense.WalkAround = v end,
        Desc = "the guard spot sits behind him, 0 walks straight into his body" })
      bool(s1, "Defensive Stance", "hold G while guarding",
        function() return CFG.Defense.HoldG end,
        function(v) CFG.Defense.HoldG = v end)
      slider(s1, { Name = "Hoop Radius", Flag = "DEF_HoopRad", Default = CFG.Defense.HoopRad,
        Min = 0, Max = 80, Suffix = " stds",
        Callback = function(v) CFG.Defense.HoopRad = v end })
      slider(s1, { Name = "Engage Radius", Flag = "DEF_Engage", Default = CFG.Defense.Engage,
        Min = 6, Max = 40, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Defense.Engage = v end })
      slider(s1, { Name = "Reaction", Flag = "DEF_Speed", Default = CFG.Defense.Speed,
        Min = 5, Max = 35,
        Callback = function(v) CFG.Defense.Speed = v end })
      slider(s1, { Name = "Standoff", Flag = "DEF_StandBase", Default = CFG.Defense.StandBase,
        Min = 2, Max = 12, Suffix = " stds",
        Callback = function(v) CFG.Defense.StandBase = v end })
      slider(s1, { Name = "Standoff On Shot", Flag = "DEF_StandShoot", Default = CFG.Defense.StandShoot,
        Min = 1, Max = 10, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Defense.StandShoot = v end })
      slider(s1, { Name = "Lead", Flag = "DEF_LeadFwd", Default = CFG.Defense.LeadFwd,
        Min = 0, Max = 0.4, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Defense.LeadFwd = v end })

      local s2 = T:Section({ Side = "Right" })
      s2:Header({ Name = "Auto Defense · Blow-By" })
      slider(s2, { Name = "Trigger Speed", Flag = "DEF_BlowbySpeed", Default = CFG.Defense.BlowbySpeed,
        Min = 5, Max = 20, Suffix = " stds/s",
        Callback = function(v) CFG.Defense.BlowbySpeed = v end })
      slider(s2, { Name = "Cut Ahead", Flag = "DEF_BlowbyAhead", Default = CFG.Defense.BlowbyAhead,
        Min = 2, Max = 14, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Defense.BlowbyAhead = v end })
      slider(s2, { Name = "Sprint From", Flag = "DEF_SprintDist", Default = CFG.Defense.SprintDist,
        Min = 1, Max = 12, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Defense.SprintDist = v end })

      local s3 = T:Section({ Side = "Left" })
      feature(s3, {
        Title = "Auto Intercept", Flag = "GRAB_Enabled",
        get = function() return CFG.Grab.Enabled end,
        set = function(v) CFG.Grab.Enabled = v; if not v then stopSteer("grab") end end
      })
      slider(s3, { Name = "Hoop Radius", Flag = "GRAB_HoopRad", Default = CFG.Grab.HoopRad,
        Min = 0, Max = 60, Suffix = " stds",
        Callback = function(v) CFG.Grab.HoopRad = v end })
      slider(s3, { Name = "Enemy Prediction", Flag = "GRAB_Lead", Default = CFG.Grab.LeadTime,
        Min = 0, Max = 0.5, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Grab.LeadTime = v end })

      bool(s3, "Only My Hoop", "ignore shots aimed at the enemy hoop",
        function() return CFG.Grab.GoalCheck end,
        function(v) CFG.Grab.GoalCheck = v end)
      bool(s3, "Only In Match", "do nothing in lobby, warmup or while spectating",
        function() return CFG.Grab.OnlyInMatch end,
        function(v) CFG.Grab.OnlyInMatch = v end)
      bool(s3, "Catch Ball", "go for any loose ball, both rims",
        function() return CFG.Grab.Catch end,
        function(v) CFG.Grab.Catch = v end)
      bool(s3, "Skip Makes", "ignore shots that go clean in, wait for the miss",
        function() return CFG.Grab.SkipMakes end,
        function(v) CFG.Grab.SkipMakes = v end)
      bool(s3, "Early Rebound", "start moving on shot start, before the ball leaves his hands",
        function() return CFG.Grab.PreCatch end,
        function(v) CFG.Grab.PreCatch = v end)
      slider(s3, { Name = "Max Chase", Flag = "GRAB_MaxRun", Default = CFG.Grab.CatchMaxRun,
        Min = 0, Max = 60, Suffix = " stds",
        Callback = function(v) CFG.Grab.CatchMaxRun = v end,
        Desc = "farther than this it leaves your movement alone" })
      slider(s3, { Name = "Catch Lead", Flag = "GRAB_CatchLead", Default = CFG.Grab.CatchLead,
        Min = 0, Max = 1, Precision = 2,
        Callback = function(v) CFG.Grab.CatchLead = v end,
        Desc = "walk this far past the catch point along the arc, 0 stands on it" })
      slider(s3, { Name = "Catch Lookahead", Flag = "GRAB_CatchAhead", Default = CFG.Grab.CatchAhead,
        Min = 0.5, Max = 3, Precision = 1, Suffix = " s",
        Callback = function(v) CFG.Grab.CatchAhead = v end })
      bool(s3, "Rim Guard", "also swat balls flying near your rim",
        function() return CFG.Grab.RimGuard end,
        function(v) CFG.Grab.RimGuard = v end)
      slider(s3, { Name = "Vertical Reach", Flag = "GRAB_ReachSet", Default = 0,
        Min = 0, Max = 32, Suffix = " stds",
        Callback = function(v) CFG.Grab.ReachSet = v end,
        Desc = "0 = measured. raise if the script ignores balls near the rim" })
      slider(s3, { Name = "Jump Earlier", Flag = "GRAB_JumpEarly", Default = CFG.Grab.JumpEarly,
        Min = 0, Max = 0.20, Precision = 3, Suffix = " s",
        Callback = function(v) CFG.Grab.JumpEarly = v end,
        Desc = "every missed catch in the log jumped late, hits jumped early" })
      slider(s3, { Name = "Rim Guard Reach", Flag = "GRAB_ReachXZ", Default = CFG.Grab.ReachXZ,
        Min = 2, Max = 14, Suffix = " stds",
        Callback = function(v) CFG.Grab.ReachXZ = v end })
      slider(s3, { Name = "Bait Guard", Flag = "GRAB_MinCommit", Default = CFG.Grab.MinCommit,
        Min = 0, Max = 0.4, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Grab.MinCommit = v end })
      slider(s3, { Name = "Camp Radius", Flag = "GRAB_CampRad", Default = CFG.Grab.CampRad,
        Min = 0, Max = 40, Suffix = " stds",
        Callback = function(v) CFG.Grab.CampRad = v end })

      s3:Divider()
      s3:Header({ Name = "Auto Move" })
      bool(s3, "Walk For Me", "go to the spot that makes the block possible",
        function() return CFG.Move2.Enabled end,
        function(v)
          CFG.Move2.Enabled = v
          if v then moveEngineOn() else stopSteer("automove") end
        end, "M2_Enabled")

      local grabPara = s3:Paragraph({ Header = "Timing", Body = "waiting for a jump" })
      task.spawn(function()
        while HUB.running do
          task.wait(0.5)
          pcall(function()
            grabPara:UpdateBody(table.concat({
              ("jump lag: %s (%d meas, %d missed)"):format(
                HUB.jumpLag and ("%.0f ms"):format(HUB.jumpLag*1000) or "estimating",
                HUB.jumpLagN or 0, HUB.jumpLagMiss or 0),
              ("block: %s"):format(tostring(HUB.blockWhy or "-")),
              ("rim: %s"):format(tostring(HUB.grabWhy or "-")),
              ("move: %s"):format(tostring(HUB.autoWhy or "off")),
              ("spot: %s"):format(tostring(HUB.spotWhy or "-")),
              ("turn: %s"):format(tostring(HUB.turnSrc or "off")),
              ("arc effect: %s"):format(HUB.arcEff
                 and ("%.3f (%d shots)"):format(HUB.arcEff, HUB.arcEffN or 0) or "default"),
            }, "\n"))
          end)
        end
      end)

      local s4 = T:Section({ Side = "Right" })
      feature(s4, {
        Title = "Contest Shooter", Flag = "BL_Enabled",
        get = function() return CFG.Blatant.Enabled end,
        set = function(v) CFG.Blatant.Enabled = v; if not v then holdRelease() end end
      })
      s4:SubLabel({ Text = "step into the shooter and hold the stance instead of chasing the ball" })
      slider(s4, { Name = "Gap", Flag = "BL_Gap", Default = CFG.Blatant.Gap,
        Min = 0.5, Max = 6, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Blatant.Gap = v end })
      slider(s4, { Name = "Stance Time", Flag = "BL_Stance", Default = CFG.Blatant.StanceTime,
        Min = 0.1, Max = 2.0, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Blatant.StanceTime = v end,
        Desc = "how long G is held, contest builds while you stand in it" })
      slider(s4, { Name = "Hold Time", Flag = "BL_HoldTime", Default = CFG.Blatant.HoldTime,
        Min = 0.03, Max = 1.0, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Blatant.HoldTime = v end,
        Desc = "how long the FAKED POSITION is held, separate from the stance" })
      slider(s4, { Name = "Dunk Rise", Flag = "BL_DunkRise", Default = CFG.Blatant.DunkRise,
        Min = 0, Max = 8, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Blatant.DunkRise = v end,
        Desc = "extra height when he goes up for a dunk or layup" })
      slider(s4, { Name = "Meter Trigger", Flag = "BL_Meter", Default = CFG.Blatant.MeterTrigger,
        Min = 0, Max = 1, Precision = 2,
        Callback = function(v) CFG.Blatant.MeterTrigger = v end,
        Desc = "step in at this much of his shot meter, 0 waits for the release" })
      slider(s4, { Name = "Hoop Radius", Flag = "BL_HoopRad", Default = CFG.Blatant.HoopRad,
        Min = 8, Max = 60, Suffix = " stds",
        Callback = function(v) CFG.Blatant.HoopRad = v end,
        Desc = "ignore shooters farther than this from our hoop" })
      bool(s4, "Engage On Windup", "step in on the gather, the shot packet is already half a ping late",
        function() return CFG.Blatant.OnWindup end,
        function(v) CFG.Blatant.OnWindup = v end, "BL_Windup")
      bool(s4, "Hold Stance", "near costs him accuracy, in stance costs him the shot",
        function() return CFG.Blatant.HoldG end,
        function(v) CFG.Blatant.HoldG = v end)

    end

    do
      local T = ctx.tabs.Movement
      local function mv(v) if v then moveEngineOn() end end

      local s1 = T:Section({ Side = "Left" })
      feature(s1, {
        Title = "Speed", Flag = "MV_Speed",
        get = function() return CFG.Move.Speed.Enabled end,
        set = function(v) CFG.Move.Speed.Enabled = v; mv(v) end
      })
      slider(s1, { Name = "Speed", Flag = "MV_SpeedVal", Default = CFG.Move.Speed.Value,
        Min = 14, Max = 60, Suffix = " stds/s",
        Callback = function(v) CFG.Move.Speed.Value = v end })

      local s15 = T:Section({ Side = "Right" })
      feature(s15, {
        Title = "Ghost Opponents", Flag = "MV_Ghost",
        get = function() return CFG.Move.GhostFoes.Enabled end,
        set = function(v) CFG.Move.GhostFoes.Enabled = v end,
        Desc = "walk straight through them, no bumps and no stun"
      })
      bool(s15, "Everyone, Not Just Your Match", nil,
        function() return CFG.Move.GhostFoes.All end,
        function(v) CFG.Move.GhostFoes.All = v end, "MV_GhostAll")
      slider(s15, { Name = "Radius", Flag = "MV_GhostRad", Default = CFG.Move.GhostFoes.Radius,
        Min = 8, Max = 60, Suffix = " stds",
        Callback = function(v) CFG.Move.GhostFoes.Radius = v end })

      s15:SubLabel({ Text = "Drops their part collision, your own state is untouched" })

      local s13 = T:Section({ Side = "Right" })
      feature(s13, {
        Title = "Contact Slip", Flag = "MV_Slip",
        get = function() return CFG.Move.Slip.Enabled end,
        set = function(v) CFG.Move.Slip.Enabled = v; if v then installMoveHook() end end,
        Desc = "a bump stuns you for 0.38 s, so it never lets you touch them"
      })
      s13:Dropdown({
        Name = "Slip Mode", Options = { "Default", "Feint" },
        Default = CFG.Move.Slip.Mode, Required = true,
        Callback = function(v) if type(v) == "string" then CFG.Move.Slip.Mode = v end end,
      }, ctx.flag("MV_SlipMode"))
      s13:SubLabel({ Text = "Default dodges one man | Feint reads him and cuts back" })
      slider(s13, { Name = "Rim Free Zone", Flag = "MV_RimFree", Default = CFG.Move.RimFree,
        Min = 0, Max = 30, Suffix = " stds",
        Callback = function(v) CFG.Move.RimFree = v end,
        Desc = "no course bending this close to the hoop, so drives stay dunks" })
      slider(s13, { Name = "Start Distance", Flag = "MV_SlipStart", Default = CFG.Move.Slip.StartMul,
        Min = 1.2, Max = 4.0, Precision = 2,
        Callback = function(v) CFG.Move.Slip.StartMul = v end,
        Desc = "in contact radii, 2.0 is about five stds, lower starts later" })
      bool(s13, "Skip When Contact Is Off",
        "on a dunk, layup, pass or shot the game does not shove at all, so walk straight through",
        function() return CFG.Move.Slip.SkipNoContact end,
        function(v) CFG.Move.Slip.SkipNoContact = v end, "MV_SlipSkip")
      slider(s13, { Name = "Slip Angle", Flag = "MV_SlipAngle", Default = CFG.Move.Slip.Angle,
        Min = 9, Max = 40, Suffix = " deg",
        Callback = function(v) CFG.Move.Slip.Angle = v end,
        Desc = "below 9 the game cancels your run instead of letting you past" })
      slider(s13, { Name = "Turn Off Him", Flag = "MV_SlipLookDeg", Default = CFG.Move.Slip.LookDeg,
        Min = 0, Max = 80, Suffix = " deg",
        Callback = function(v) CFG.Move.Slip.LookDeg = v end,
        Desc = "eyes off the man in stance, facing him is what invites the push" })
      slider(s13, { Name = "Stance Range", Flag = "MV_StanceRange", Default = CFG.Move.Slip.StanceRange,
        Min = 6, Max = 24, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Move.Slip.StanceRange = v end,
        Desc = "a man in stance this close makes it start looking for space" })
      slider(s13, { Name = "Keep Away", Flag = "MV_SlipKeep", Default = CFG.Move.Slip.KeepGap,
        Min = 4, Max = 24, Precision = 1, Suffix = " stds",
        Callback = function(v) CFG.Move.Slip.KeepGap = v end,
        Desc = "same trigger for anyone not in stance" })
      slider(s13, { Name = "Open Enough", Flag = "MV_Open", Default = CFG.Move.Slip.Open,
        Min = 6, Max = 30, Suffix = " stds",
        Callback = function(v) CFG.Move.Slip.Open = v end,
        Desc = "past this he no longer contests, so no reason to run further" })
      slider(s13, { Name = "Step Out", Flag = "MV_StepOut", Default = CFG.Move.Slip.StepOut,
        Min = 5, Max = 22, Suffix = " stds",
        Callback = function(v) CFG.Move.Slip.StepOut = v end,
        Desc = "how far ahead the candidate spots sit" })
      slider(s13, { Name = "Follow Input", Flag = "MV_InputW", Default = CFG.Move.Slip.InputWeight,
        Min = 0, Max = 3, Precision = 2,
        Callback = function(v) CFG.Move.Slip.InputWeight = v end,
        Desc = "0 goes purely for space, high keeps your own direction" })
      slider(s13, { Name = "Max Turn", Flag = "MV_MaxTurn", Default = CFG.Move.Slip.MaxTurn,
        Min = 15, Max = 85, Suffix = " deg",
        Callback = function(v) CFG.Move.Slip.MaxTurn = v end,
        Desc = "hard cap on how far it may bend you off your own keys" })
      slider(s13, { Name = "Commit", Flag = "MV_FeintCommit", Default = CFG.Move.Slip.CommitTime,
        Min = 0.08, Max = 0.8, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Move.Slip.CommitTime = v end,
        Desc = "how long a chosen lane is favoured, short jitters" })
      bool(s13, "Fake The Look", "eyes turn away from the run so it is not telegraphed",
        function() return CFG.Move.Slip.LookFake end,
        function(v) CFG.Move.Slip.LookFake = v end, "MV_LookFake")
      slider(s13, { Name = "Look Angle", Flag = "MV_LookOff", Default = CFG.Move.Slip.LookOff,
        Min = 0, Max = 70, Suffix = " deg",
        Callback = function(v) CFG.Move.Slip.LookOff = v end,
        Desc = "past 41 the game starts cutting speed unless Strafer is on" })
      slider(s13, { Name = "Zone Radius", Flag = "MV_ZoneRad", Default = CFG.Move.Slip.ZoneRad,
        Min = 8, Max = 45, Suffix = " stds",
        Callback = function(v) CFG.Move.Slip.ZoneRad = v end,
        Desc = "further than this from the rim it stops feinting entirely" })

      local s2 = T:Section({ Side = "Right" })
      feature(s2, {
        Title = "Fly", Flag = "MV_Fly",
        get = function() return CFG.Move.Fly.Enabled end,
        set = function(v) CFG.Move.Fly.Enabled = v; mv(v) end,
        Desc = "WASD, Space up, LeftShift down"
      })
      slider(s2, { Name = "Fly Speed", Flag = "MV_FlyVal", Default = CFG.Move.Fly.Speed,
        Min = 10, Max = 200, Suffix = " stds/s",
        Callback = function(v) CFG.Move.Fly.Speed = v end })

      local s14 = T:Section({ Side = "Right" })
      feature(s14, {
        Title = "NoClip", Flag = "MV_NoClip",
        get = function() return CFG.Move.NoClip.Enabled end,
        set = function(v) CFG.Move.NoClip.Enabled = v end,
        Desc = "drops collision on the proxy body, restored when turned off"
      })
      s14:SubLabel({ Text = "Collisions live on ProxyCharacter, the real root is anchored" })

      local s3 = T:Section({ Side = "Left" })
      feature(s3, {
        Title = "Strafer", Flag = "MV_Strafe",
        get = function() return CFG.Move.Strafe.Enabled end,
        set = function(v) CFG.Move.Strafe.Enabled = v; mv(v) end,
        Desc = "keeps full speed sideways and backwards"
      })
      bool(s3, "No Sideways Penalty", nil,
        function() return CFG.Move.Strafe.Side end,
        function(v) CFG.Move.Strafe.Side = v end)
      bool(s3, "No Backpedal Penalty", nil,
        function() return CFG.Move.Strafe.Back end,
        function(v) CFG.Move.Strafe.Back = v end)
      bool(s3, "Shooting Strafe",
        "keep moving and sprinting once the shot is away, not while holding it",
        function() return CFG.Move.Strafe.Shooting end,
        function(v) CFG.Move.Strafe.Shooting = v end, "MV_ShootStrafe")

      local s4 = T:Section({ Side = "Right" })
      feature(s4, {
        Title = "Sprint Speed", Flag = "MV_Sprint",
        get = function() return CFG.Move.Sprint.Enabled end,
        set = function(v) CFG.Move.Sprint.Enabled = v; mv(v) end
      })
      slider(s4, { Name = "Sprint Bonus", Flag = "MV_SprintBonus", Default = CFG.Move.Sprint.Bonus,
        Min = 0, Max = 25, Precision = 2,
        Callback = function(v) CFG.Move.Sprint.Bonus = v end,
        Desc = "game default is 3.35" })

      local s5 = T:Section({ Side = "Left" })
      feature(s5, {
        Title = "Infinite Stamina", Flag = "MV_Stamina",
        get = function() return CFG.Stamina.Enabled end,
        set = function(v) CFG.Stamina.Enabled = v end
      })

      s5:Divider()
      local s6 = s5
      feature(s6, {
        Title = "Auto Sprint", Flag = "MV_AutoSprint",
        get = function() return CFG.Move.AutoSprint.Enabled end,
        set = function(v) CFG.Move.AutoSprint.Enabled = v; mv(v) end
      })

      local s7 = T:Section({ Side = "Left" })
      feature(s7, {
        Title = "No Stun", Flag = "MV_NoStun",
        get = function() return CFG.Move.NoStun.Enabled end,
        set = function(v) CFG.Move.NoStun.Enabled = v end
      })

      local s8 = T:Section({ Side = "Left" })
      feature(s8, {
        Title = "No Cooldown", Flag = "MV_NoCooldown",
        get = function() return CFG.Move.NoCooldown.Enabled end,
        set = function(v) CFG.Move.NoCooldown.Enabled = v end
      })

      local s10 = T:Section({ Side = "Right" })
      feature(s10, {
        Title = "Movement Presets", Flag = "MV_Preset",
        get = function() return CFG.Move.Preset.Enabled end,
        set = function(v) CFG.Move.Preset.Enabled = v; mv(v) end,
        Desc = "rewrites speed and turning per movement state"
      })
      bool(s10, "Remove All Slowdowns", nil,
        function() return CFG.Move.Preset.FlattenAll end,
        function(v) CFG.Move.Preset.FlattenAll = v end)
      -- Тот же список, что игра присваивает CurrentMovementType.
      local presetNames = { "Base", "Guard", "Post", "Boxout", "BoxoutPlayer",
                            "Call", "Retreat", "TipOff", "GoKart", "Sit" }
      local chosen = "Post"
      local mulEl, turnEl

      local FAL_PRESET = ctx.flag("MV_PresetData")
      local ML = ctx.MacLib
      local function savePreset()
        if not (ML and ML.FALSetData) then return end
        pcall(function()
          ML:FALSetData(FAL_PRESET, { Mul = CFG.Move.Preset.Mul,
                                      Turn = CFG.Move.Preset.Turn })
        end)
      end
      if ML and ML.FALLoadData then
        pcall(function()
          ML:FALLoadData(FAL_PRESET, function(data)
            if type(data) ~= "table" then return end
            for _, k in ipairs(presetNames) do
              if type(data.Mul)  == "table" and type(data.Mul[k])  == "number" then
                CFG.Move.Preset.Mul[k] = data.Mul[k]
              end
              if type(data.Turn) == "table" and type(data.Turn[k]) == "number" then
                CFG.Move.Preset.Turn[k] = data.Turn[k]
              end
            end
            if mulEl  then pcall(function() mulEl:UpdateValue(CFG.Move.Preset.Mul[chosen] or 1, true) end) end
            if turnEl then pcall(function() turnEl:UpdateValue(CFG.Move.Preset.Turn[chosen] or 0, true) end) end
          end, 0.5)
        end)
      end
      s10:SubLabel({ Text = "pick a state, then edit the two sliders below" })
      s10:Dropdown({
        Name = "State", Options = presetNames, Default = chosen, Required = true,
        Callback = function(v)
          -- из восстановленного конфига дропдаун может прийти nil, а дальше
          -- идёт индексация Mul[chosen] — nil-ключ уронил бы её
          if type(v) ~= "string" then return end
          chosen = v
          if mulEl  then pcall(function() mulEl:UpdateValue(CFG.Move.Preset.Mul[v] or 1, true) end) end
          if turnEl then pcall(function() turnEl:UpdateValue(CFG.Move.Preset.Turn[v] or 0, true) end) end
        end,
      }, ctx.flag("MV_PresetPick"))
      mulEl = slider(s10, { Name = "Speed Multiplier", Flag = "MV_PresetMul",
        Default = CFG.Move.Preset.Mul[chosen] or 1, Min = 0.3, Max = 2.5, Precision = 2,
        Callback = function(v) CFG.Move.Preset.Mul[chosen] = v; savePreset() end })
      turnEl = slider(s10, { Name = "Turn Response", Flag = "MV_PresetTurn",
        Default = CFG.Move.Preset.Turn[chosen] or 0, Min = 0, Max = 30,
        Callback = function(v) CFG.Move.Preset.Turn[chosen] = v; savePreset() end,
        Desc = "0 keeps the game's smoothing" })
      for _, el in ipairs({ mulEl, turnEl }) do
        if el then pcall(function() el.IgnoreConfig = true end) end
      end

      local s11 = T:Section({ Side = "Left" })
      feature(s11, {
        Title = "Move Keybinds", Flag = "MV_Moves",
        get = function() return CFG.Move.Moves.Enabled end,
        set = function(v)
          CFG.Move.Moves.Enabled = v
          if v then installMoveKeys() end
          rebuildMoveMap()
        end,
        Desc = "rebind the game moves that it locks to fixed keys"
      })

      local function toKey(v, fallback)
        if typeof(v) == "EnumItem" then return v end
        if type(v) == "string" then
          return Enum.KeyCode[v] or Enum.UserInputType[v] or fallback
        end
        return fallback
      end
      local function keyName(k)
        if typeof(k) == "EnumItem" then return k.Name end
        return tostring(k)
      end

      local RESERVED = {
        [Enum.KeyCode.Space]     = "Shoot / Jump",
        [Enum.KeyCode.E]         = "Shoot",
        [Enum.KeyCode.F]         = "Intentional foul",
        [Enum.KeyCode.P]         = "Drop ball",
        [Enum.KeyCode.B]         = "Celebrations",
        [Enum.KeyCode.L]         = "Camera mode",
        [Enum.KeyCode.Tab]       = "Scoreboard",
        [Enum.KeyCode.LeftAlt]   = "Quick chat",
        [Enum.KeyCode.LeftShift] = "Sprint",
      }
      for _, d in ipairs({ "One","Two","Three","Four","Five","Six","Seven","Eight","Nine" }) do
        RESERVED[Enum.KeyCode[d]] = "Pass"
      end

      local function keyTaken(me, k)
        if k == me.key then return nil end
        for _, o in ipairs(GAME_MOVES) do
          if o.id ~= me.id then
            local ek = CFG.Move.Moves.Bind[o.id] or o.key
            if ek == k then return o.Name end
          end
        end
        return RESERVED[k]
      end

      local moveEls = {}

      local function applyBind(m, nb, loud)
        if nb == nil then nb = m.key end
        if CFG.Move.Moves.Bind[m.id] == nb then return true end
        local by = keyTaken(m, nb)
        if by then
          if loud then
            say("Move Keybinds", ("%s is taken by %s"):format(keyName(nb), by))
          end
          local back = CFG.Move.Moves.Bind[m.id] or m.key
          local el = moveEls[m.id]

          if el and el.Bind then
            task.defer(function() pcall(function() el:Bind(back) end) end)
          end
          return false
        end
        CFG.Move.Moves.Bind[m.id] = nb
        rebuildMoveMap()
        return true
      end

      for _, m in ipairs(GAME_MOVES) do
        local el
        el = ctx.keybind(s11, {
          Name    = m.Name,
          Flag    = ctx.flag("MV_MoveKB_" .. m.id),
          Default = m.key,
          Toggle  = function() pressMove(m) end,
          OnBinded = function(key)
            local b = toKey(key, nil)
            if b == nil and el and el.GetBind then
              pcall(function() b = toKey(el:GetBind(), nil) end)
            end
            applyBind(m, b, true)
          end
        })
        moveEls[m.id] = el
      end

      task.spawn(function()
        while HUB.running do
          task.wait(0.2)
          for _, m in ipairs(GAME_MOVES) do
            local el = moveEls[m.id]
            if el and el.GetBind then
              local b = nil
              pcall(function() b = toKey(el:GetBind(), nil) end)
              applyBind(m, b, false)
            end
          end
        end
      end)

    end

    do
      local T = ctx.tabs.Visuals

      local s1 = T:Section({ Side = "Left" })
      feature(s1, {
        Title = "Ball Trajectory", Flag = "VZ_Traj",
        get = function() return CFG.Traj.Enabled end,
        set = function(v) CFG.Traj.Enabled = v; if not v then hideAll() end end
      })

      slider(s1, { Name = "Length", Flag = "VZ_Duration", Default = CFG.Traj.Duration,
        Min = 0.5, Max = 4.0, Precision = 1, Suffix = " s",
        Callback = function(v) CFG.Traj.Duration = v end })
      slider(s1, { Name = "Thickness", Flag = "VZ_Thick", Default = CFG.Traj.Thick,
        Min = 1, Max = 6,
        Callback = function(v) CFG.Traj.Thick = v end })
      s1:Colorpicker({ Name = "Scores Color", Default = CFG.Traj.ColorIn,
        Callback = function(c) CFG.Traj.ColorIn = c end }, ctx.flag("VZ_ColIn"))
      s1:Colorpicker({ Name = "Misses Color", Default = CFG.Traj.ColorOut,
        Callback = function(c) CFG.Traj.ColorOut = c end }, ctx.flag("VZ_ColOut"))
      bool(s1, "Impact Marks", nil,
        function() return CFG.Traj.Marks end,
        function(v) CFG.Traj.Marks = v; if not v then hideAll() end end)
      bool(s1, "Hide Teammate Shots", nil,
        function() return CFG.Traj.SkipTeammates end,
        function(v) CFG.Traj.SkipTeammates = v end)

      local s2 = T:Section({ Side = "Right" })
      s2:Header({ Name = "Ball Detection" })
      slider(s2, { Name = "Min Speed", Flag = "MS_MinSpeed", Default = CFG.Traj.MinSpeed,
        Min = 1, Max = 30, Suffix = " stds/s",
        Callback = function(v) CFG.Traj.MinSpeed = v end })
      slider(s2, { Name = "Hold Distance", Flag = "MS_HoldDist", Default = CFG.Traj.HoldDist,
        Min = 3, Max = 14, Suffix = " stds",
        Callback = function(v) CFG.Traj.HoldDist = v end })
      slider(s2, { Name = "Ball Poll", Flag = "MS_TagEvery", Default = CFG.Traj.TagEvery,
        Min = 0.05, Max = 1.0, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Traj.TagEvery = v end })
      slider(s2, { Name = "Deep Scan", Flag = "MS_ScanEvery", Default = CFG.Traj.ScanEvery,
        Min = 1, Max = 10, Suffix = " s",
        Callback = function(v) CFG.Traj.ScanEvery = v end })
      slider(s2, { Name = "Flight Hold", Flag = "MS_FlightHold", Default = CFG.Traj.FlightHold,
        Min = 0.05, Max = 0.6, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Traj.FlightHold = v end })
    end

    do
      local T = ctx.tabs.Misc

      local s1 = T:Section({ Side = "Left" })
      s1:Header({ Name = "Anti AFK" })
      bool(s1, "Enabled", nil,
        function() return HUB.antiAfk == true end,
        function(v)
          HUB.antiAfk = v
          if v then
            pcall(function()
              local c = getconnections and getconnections(LP.Idled)
              if c then for _, cn in ipairs(c) do pcall(function() cn:Disable() end) end end
            end)
          end
        end, "MS_AntiAfk")

      local s4 = T:Section({ Side = "Right" })
      s4:Header({ Name = "Look At Ball" })
      bool(s4, "Enabled", "turn toward the ball while it flies",
        function() return CFG.Grab.FaceBall end,
        function(v) CFG.Grab.FaceBall = v end, "MS_FaceBall")

      slider(s4, { Name = "Turn Rate", Flag = "MS_TurnRate", Default = CFG.Grab.CatchFaceRate,
        Min = 2, Max = 60, Precision = 1, Suffix = " rad/s",
        Callback = function(v) CFG.Grab.CatchFaceRate = v end })
      slider(s4, { Name = "Jump Cooldown", Flag = "MS_JumpCD", Default = CFG.Grab.JumpCD,
        Min = 0.1, Max = 1.5, Precision = 2, Suffix = " s",
        Callback = function(v) CFG.Grab.JumpCD = v end })
    end

    do
      local T = ctx.tabs.Debug

      local s1 = T:Section({ Side = "Left" })
      s1:Header({ Name = "Dump" })
      s1:SubLabel({ Text = ("module v%d"):format(VERSION) })
      s1:SubLabel({ Text = "folder: " .. CFG.Debug.Folder })
      s1:Button({ Name = "Save Dump", Callback = function()
        save()
        say("Dump", HUB.lastDumpPath and ("saved: " .. HUB.lastDumpPath) or "could not save")
      end }, ctx.flag("DB_Save_B"))
      ctx.keybind(s1, { Name = "Keybind", Flag = ctx.flag("DB_Save_KB"),
        Toggle = function() save() end })
      bool(s1, "Copy", nil,
        function() return CFG.Debug.Copy end,
        function(v) CFG.Debug.Copy = v end)
      s1:Button({ Name = "Clear Shots", Callback = function()
        HUB.shots = {}; HUB.stats = {}; HUB.shotsTotal = 0
        say("Dump", "cleared")
      end }, ctx.flag("DB_Clear_B"))

      s1:Divider()
      s1:Header({ Name = "Remote Probe" })
      s1:SubLabel({ Text = "asks the server for things it should refuse" })
      s1:Button({ Name = "Run Probe", Callback = function()
        task.spawn(function()
          local ok, res = pcall(PBX.probe)
          if ok then
            local hits = select(2, tostring(res):gsub("%[OPEN%]", ""))
            say("Probe", ("%d open, saved to %s/probe.txt")
              :format(hits, CFG.Debug.Folder))
          else
            say("Probe", "failed: " .. tostring(res):sub(1, 60))
          end
        end)
      end }, ctx.flag("DB_Probe_B"))

      local s2 = T:Section({ Side = "Right" })
      s2:Header({ Name = "Status" })
      local para = s2:Paragraph({ Header = "Live", Body = "collecting..." })
      s2:Button({ Name = "Refresh", Callback = function() HUB.statusNow = true end },
        ctx.flag("DB_Refresh_B"))

      s2:Button({ Name = "Reset Physics", Callback = function()
        unstick(); say("Unstick", "reset")
      end }, ctx.flag("MV_Unstick_B"))
      ctx.keybind(s2, { Name = "Reset Keybind", Flag = ctx.flag("MV_Unstick_KB"),
        Toggle = function() unstick() end })
      task.spawn(function()
        while HUB.running do
          task.wait(0.5)
          pcall(function()
            local tot = 0; for _, v in pairs(HUB.stats) do tot += v end
            para:UpdateBody(table.concat({
              ("ping %.0f ms (%s)"):format(dataPing()*1000, tostring(HUB.pingSource)),
              ("ball %s, speed %.1f, points %d"):format(tostring(BALL.state), BALL.speed or 0, BALL.fitN or 0),
              ("meter rate %s"):format(tostring(HUB.lastRate or "-")),
              ("hoops %d (%s)"):format(#hoopList(), tostring(hoopSrc)),
              ("defend from %s"):format(tostring(HUB.defendSrc)),
              ("input hook %s, ok %s"):format(tostring(HUB.pmSrc or "off"), tostring(HUB.moveOK)),
              ("steering owner %s"):format(tostring(HUB.moveOwner or "you")),
              ("anti defense %s"):format(tostring(HUB.antiWhy or "off")),
              ("velocity hook %s"):format(tostring(HUB.velSrc or "off")),
              ("jump lag %s (%d meas)"):format(
                 HUB.jumpLag and ("%.0f ms"):format(HUB.jumpLag*1000) or "not measured",
                 HUB.jumpLagN or 0),
              ("intercept %s"):format(tostring(HUB.grabWhy or "-")),
              ("block %s"):format(tostring(HUB.blockWhy or "-")),
              ("key remap %s"):format(tostring(HUB.moveKeyInfo or "off")),
              ("last move sent %s"):format(tostring(HUB.moveKeyPath or "-")),
              ("state %s"):format(tostring(HUB.mov and rawget(HUB.mov, "CurrentMovementType") or "-")),
              ("shots %d, perfect %d/%d"):format(HUB.shotsTotal or #HUB.shots, HUB.stats["Perfect"] or 0, tot),
              ("turn hook %s, applied %s"):format(tostring(HUB.turnSrc or "off"),
                 HUB.turnApplied and ("%.1fs ago"):format(os.clock()-HUB.turnApplied) or "never"),
              ("fit dropped %d outliers"):format(HUB.fitDropped or 0),
              (function()
                local Q = HUB.predQ
                local a8 = (Q and Q.fit8 and Q.fit8.n > 0) and (Q.fit8.sum/Q.fit8.n) or nil
                return ("predict err %s"):format(a8
                  and ("%.2f avg, %.2f max, n=%d"):format(a8, Q.fit8.max, Q.fit8.n)
                  or "no data")
              end)(),
              ("arc effect %s"):format(HUB.arcEff
                 and ("%.3f (%d flights)"):format(HUB.arcEff, HUB.arcEffN or 0) or "default"),
              (function()
                local b = HUB.arcEffB or {}
                return ("arc near/mid/far %s / %s / %s"):format(
                  b.near and ("%.2f"):format(b.near) or "-",
                  b.mid  and ("%.2f"):format(b.mid)  or "-",
                  b.far  and ("%.2f"):format(b.far)  or "-")
              end)(),
              ("jump lag rejected %d"):format(HUB.jumpLagBad or 0),
              (function()
                local jl = HUB.jumpLog or {}
                if #jl == 0 then return "jump timing: no data yet" end
                local s = 0
                for _, e in ipairs(jl) do s += e.arrErr or 0 end
                return ("jump timing %+.0f ms over %d (plus = jumped early)")
                  :format(s / #jl, #jl)
              end)(),
              (function()
                local Q = HUB.predQ
                local a = (Q and Q.shot and Q.shot.n > 0) and (Q.shot.sum/Q.shot.n) or nil
                return ("free flight err %s"):format(a
                  and ("%.2f avg, %.2f max, n=%d"):format(a, Q.shot.max, Q.shot.n)
                  or "no data")
              end)(),
              ("slip %s"):format(HUB.slipOn
                 and ("angled %.1fs ago"):format(os.clock()-HUB.slipOn) or "idle"),
              ("kept distance %s"):format(HUB.slipKeep
                 and ("%.1fs ago"):format(os.clock()-HUB.slipKeep) or "never"),
              ("last bump %s"):format(HUB.slipHit
                 and ("%s, %.1fs ago"):format(tostring(HUB.slipHitAct), os.clock()-HUB.slipHit)
                 or "none"),
              ("match %s"):format(tostring(PK.src)),
            }, "\n"))
          end)
        end
      end)
    end

    uiReady = true
  end

  function M.stop()  HUB.unload() end
  M.unload = M.stop
  return M
end
