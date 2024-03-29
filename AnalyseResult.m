% =========================================================================
%> @section INTRO AnalyseResult
%>
%> AnalyseResult 결과를 분석하는 함수
%>
%> @version 0.21
%> @see AccumulateUpstreamFlow(), CalcFacetFlow(), CalcInfinitiveFlow()
%>      ,CalcSDSFlow(), DefineUpliftRateDistribution(), FindSDSDryNbr()
%>      ,IsBoundary(), IsDry(), LoadParameterValues(), ProcessSink()
%>      ,ReadParameterValue(), hypsometry(), streamorder(), wflowacc()
%>      
%>
%> @retval majorOutputs              : 주요 결과를 저장한 자료
%>
%> @param OUTPUT_SUBDIR             : 출력 파일이 저장된 디렉터리
%> @param GRAPH_INTERVAL            : 모의결과가 기록된 파일에서 그래프를 보여주는 간격
%> @param startedTimeStepNo         : 그래프 출력 시점
%> @param achievedRatio             : 총 모의기간중 결과가 나온 부분의 비율
%> @param EXTRACT_INTERVAL          : (그래프를 보여주는 동안) (2차원) 주요 변수를 저장하는 간격
%> @param SHOW_GRAPH                : 주요 결과를 그래프로 보여줄 것인지를 지정함
%>
%>
%> * 분석내용
%>  01. 3차원 DEM
%>  02. 등고선도
%>  03. 퇴적층 두께
%>  04. 경사
%>  05. 풍화율
%>  06. 사면작용에 의한 퇴적층 두께 변화율
%>  07. 빠른 사면작용에 의한 퇴적층 두께 변화율
%>  08. 빠른 사면작용에 의한 기반암 고도 변화율
%>  09. flooded region 분포
%>  10. 만제유량
%>  11. 하천작용에 의한 퇴적층 두께 변화율
%>  12. 하천작용에 의한 기반암 고도 변화율
%>  13. 물질운반환경 분류
%>  14. 누적 침식량
%>  15. TPI
%>  16. 영동과 영서지역 분수계 (등고선도 위)
%>  17. 횡단곡선상 속성 (AnalyseFinalResult 함수 입력변수)
%>      : 사면 퇴적층 평균 두께, 하천 퇴적층 평균 두께, 사면작용에 의한 퇴적층
%>        두께 변화율, 하천에 의한 퇴적층 두께 변화율, 융기율, 풍화율
%>  18. 하천종단곡선 속성
%>      : 기반암 하상 고도, 기반암 하상 + 퇴적층 평균 두께
%>  19. 유역분지 특성
%>      : 평균고도, 평균경사, 평균 풍화율, 하계밀도, 운반환경비율 ..
%>  20. 영서와 영동 유역 평균 침식률과 융기율
%>      : 침식율과 융기율
%>  21. 퇴적물 수지
%>      : 유역 (평균) 퇴적물 수지, 하도 내 하상 퇴적물 수지
%>  22. 하계망과 (스르랄러의) 하천차수
%>  23. 힙소메트리 곡선
%>
%> * 주의:
%>  - EXTRACT_INTERVAL
%>    : GRAPH_INTERVAL과 같거나 작은 약수만 됨
%>    : 주요 1차원 변수는 그래프를 보여주는 간격과 동일하게 저장함
%>  - SHOW_GRAPH
%>    : 1: 그래프로 보여줌
%>    : 2: 그래프로 보여주지 않음
%>
%> * History
%>  - 2011/10/27
%>   - 물질운반환경 그래프 알고리듬 수정함
%>  - 2011/10/06
%>   - 주석문을 조금 더 구조화c
%>  - 2010/09/28
%>   - 정지된 모의결과를 연속해서 할 수 있도록 수정함
%>   - 주요 변수 저장함
%>   - 외적 지형형성작용에 의한 고도변화가 있기 전 퇴적층 두께 및 기반암 고도를 이용함
%>
% =========================================================================
function majorOutputs = AnalyseResult(OUTPUT_SUBDIR,PARAMETER_VALUES_FILE,GRAPH_INTERVAL,startedTimeStepNo,achievedRatio,EXTRACT_INTERVAL,SHOW_GRAPH)
%
% function Analyse2DResult
%

%==========================================================================
% 1. 상수 및 변수 초기화
% * 주의: GPSSMain() 시작부분과 유사함. 따라서 GPSSMain()에서 가져오면 됨.
% * 동일한 부분
%   : 출력파일 상수 정의
%   : 중요한 초기 변수값 입력
%   : 출력파일경로 상수 정의
%   : 각 출력파일 열기
%   : 그외 상수 및 변수 초기화
%   : 모의기간동안 융기율의 시,공간 분포 정의
% * 다른 부분
%   : 입력변수 점검
%   : 출력 디렉터리에 있는 parameterValues.txt를 불러옴
%   : INPUT_FILE_PARAM_PATH = fullfile(INPUT_DIR_PATH,parameterValuesFile); 생략함
%   : 출력파일을 read 모드로 엶
%   : MakeInitialGeomorphology() 생략함
%   : mRows, nCols는 FID_LOG 파일을 통해 불러옴

% 1) 모의결과 출력파일들을 일단 열어두고 구동시의 초기변수 입력값을 읽음
%--------------------------------------------------------------------------
% GPSSMain()과 다른 부분
%--------------------------------------------------------------------------

% 입력변수 점검
if mod(GRAPH_INTERVAL,EXTRACT_INTERVAL) ~= 0
    error('주요 2차원 변수를 저장하는 간격은 그래프를 보여주는 간격의 약수여야 합니다.');    
end

% 출력 디렉터리에 있는 parameterValues.txt 를 볼러옴
DATA_DIR = 'data';      % 입출력 파일을 저장하는 최상위 디렉터리
OUTPUT_DIR = 'output';  % 출력 파일을 저장할 디렉터리
parameterValuesFile = PARAMETER_VALUES_FILE;    % 초기 입력값 파일
OUTPUT_DIR_PATH = fullfile(DATA_DIR,OUTPUT_DIR);
INPUT_FILE_PARAM_PATH ... % 입력 파일 경로 상수
    = fullfile(OUTPUT_DIR_PATH,OUTPUT_SUBDIR,parameterValuesFile);

%--------------------------------------------------------------------------
% GPSSMain()과 같은 부분
%--------------------------------------------------------------------------

% 출력 파일 상수 : 모의 결과를 기록하는 파일
OUTPUT_FILE_SEDTHICK ...                % i번째 퇴적층 두께 [m]
    = 'sedThick.txt';
OUTPUT_FILE_BEDROCKELEV ...             % i번째 기반암 고도 [m]
    = 'bedrockElev.txt';
OUTPUT_FILE_WEATHER ...                 % 풍화율 [m/dT]
    = 'weatherProduct.txt';
OUTPUT_FILE_dSEDTHICK_BYHILLSLOPE ...   % 사면작용에 의한 퇴적층 두께 변화율 [m^3/m^2 dT]
    = 'dSedThickByHillslope.txt';
OUTPUT_FILE_CHANBEDSEDBUDGET ...        % 사면작용에 의한 하도 양안으로부터 하도로의 공급율 [m^3/m^2 dT]
    = 'chanBedSedBudget.txt';
OUTPUT_FILE_dSEDTHICK_BYFLUVIAL ...     % 하천작용에 의한 퇴적층 두께 변화율 [m^3/m^2 dT]
    = 'dSedThickByFluvial.txt';
OUTPUT_FILE_dBEDROCKELEV_BYFLUVIAL ...  % 하천작용에 의한 기반암 고도 변화율 [m^3/m^2 dT]
    = 'dBedrockElevByFluvial.txt';
OUTPUT_FILE_dSEDTHICK_BYRAPIDMASS ...   % 빠른 매스무브먼트에 의한 퇴적층 두께 변화율 [m^3/m^2 dT]
    = 'dSedThickByRapidMassmove.txt';
OUTPUT_FILE_dBEDROCKELEV_BYRAPIDMASS ... % 빠른 매스무브먼트에 의한 기반암 고도 변화율 [m^3/m^2 dT]
    = 'dBedrockElevByRapidMassmove.txt';
OUTPUT_FILE_LOG ...                     % GPSSMain() 구동 동안의 상황 기록
    = 'log.txt';

% 중요한 초기 변수값을 입력함
%--------------------------------------------------------------------------
% GPSSMain()과 다른 부분
% : INPUT_FILE_PARAM_PATH = fullfile(INPUT_DIR_PATH,parameterValuesFile); 생략함
%--------------------------------------------------------------------------
[OUTPUT_SUBDIR ...          % 출력 파일을 저장할 세부 디렉터리
,Y ...                      % (초기 지형을 만들 경우) 외곽 경계를 제외한 Y축 크기
,X ...                      % (초기 지형을 만들 경우) 외곽 경계를 제외한 X축 크기
,dX ...                     % 셀 크기
,PLANE_ANGLE ...            % (초기 지형을 만들 경우) 평탄면의 경사 [m/m]
,INIT_BEDROCK_ELEV_FILE ... % (초기 지형을 불러올 경우) 초기 지형을 저장한 파일
,initSedThick ...           % 초기 퇴적층 두께 [m]
,INIT_SED_THICK_FILE ...    % 초기 지형의 퇴적층 두께를 불러올 경우 이를 저장한 파일
,TIME_STEPS_NO ...          % 총 실행 횟수
,INIT_TIME_STEP_NO ...      % 이전 모형 결과에서 이어서 할 경우의 초기 실행 횟수
,dT ...                     % TIME_STEPS_NO를 줄이기 위한 만제유량 재현기간 [yr]
,WRITE_INTERVAL ...         % 모의 결과를 출력하는 빈도 결정
,BOUNDARY_OUTFLOW_COND ...  % 모델 영역으로부터 유출이 발생하는 유출구 또는 경계를 지정
,TOP_BOUNDARY_ELEV_COND ...     % 위 외곽 경계 고도 조건
,IS_LEFT_RIGHT_CONNECTED ...    % 좌우 외곽 경계 연결을 결정
,TOTAL_ACCUMULATED_UPLIFT ...   % 모의 기간 동안 총 지반 융기량 [m]
,IS_TILTED_UPWARPING ...        % 경동성 요곡 지반융기 운동을 결정
,UPLIFT_AXIS_DISTANCE_FROM_COAST ...    % 해안선으로부터 융기축까지의 거리 [m]
,RAMP_ANGLE_TO_TOP ...          % (누적 지반 융기량을 기준) 융기축에서 위 경계로의 각
,Y_TOP_BND_FINAL_ELEV ...       % 위 경계의 최종 고도
,UPLIFT_RATE_TEMPORAL_DISTRIBUTION_COND ... % 융기율의 시간적 분포 결정
,acceleratedUpliftPhaseNo ...   % (간헐적 융기조건) 모의기간 동안 높은 융기율이 발생하는 빈도
,dUpliftRate ...            % (간헐적 융기조건) 평균 연간 융기율을 기준으로 최대 최소 융기율의 차이 비율
,upliftRate0 ...            % (융기율 감소조건) 융기율 감쇠분포의 초기 융기율 [m/yr]
,waveArrivalTime ...        % (경동성 요곡 지반융기 조건) 영서 외곽 경계 고도가 본격적으로 하강하는 시점 (모의 기간에서 비율)
,initUpliftRate ...         % (경동성 요곡 지반융기 조건) 본격적 하강 이전 침식 기준면 하강율 [m/yr]
,kw0 ...                    % 선형 풍화함수에서 연장되는 노출 기반암의 풍화율 [m/yr]
,kwa ...                    % 선형 풍화함수의 증가율
,kw1 ...                    % 지수 감소 풍화함수에서 연장되는 노출 기반암의 풍화율 [m/yr]
,kwm ...                    % 풍화층 두께 축적 [m]
,kmd ...                    % 사면작용의 확산 계수
,soilCriticalSlopeForFailure ... % 천부활동의 안정 사면각
,rockCriticalSlopeForFailure ... % 기반암활동의 안정 사면각
,annualPrecipitation ...    % 연 강우량 [m/yr]
,annualEvapotranspiration ... % 연 증발산량 [m/yr]
,kqb ...                    % 평균유량과 만제유량과의 관계식에서 계수
,mqb ...                    % 평균유량과 만제유량과의 관계식에서 지수
,bankfullTime ...           % 만제유량 지속 기간 [s]
,timeWeight ...             % 만제유량 지속기간을 줄이기 위한 침식율 가중치
,minSubDT ...               % 최소한의 세부단위 시간 [s]
,khw ...                    % 만제유량과 하폭과의 관계식에서 계수
,mhw ...                    % 만제유량과 하폭과의 관계식에서 지수
,khd ...                    % 만제유량과 수심과의 관계식에서 계수
,mhd ...                    % 만제유량과 수심과의 관계식에서 지수
,FLUVIALPROCESS_COND ...    % flooded region의 순 퇴적물 두께 변화율을 추정하는 방법
,channelInitiation ...      % 하천 시작 지점 임계값
,criticalUpslopeCellsNo ... % 하천 시작 임계 상부유역 셀 개수
,mfa ...                    % 하천에 의한 퇴적물 운반율 수식에서 유량의 지수
,nfa ...                    % 하천에 의한 퇴적물 운반율 수식에서 경사의 지수
,fSRho ...                  % 운반되는 퇴적물의 평균 밀도
,fSD50 ...                  % 운반되는 퇴적물의 중간 입경
,eta ...                    % 운반되는 퇴적물의 평균 공극율
,nA ...                     % 충적 하천 하도에서의 Manning 저항 계수
,mfb ...                    % 기반암 하상 침식율 수식에서 유량의 지수
,nfb ...                    % 기반암 하상 침식율 수식에서 경사의 지수
,kfbre ...                  % 기반암 하상 연약도
,nB] ...                    % 기반암 하상 하도에서의 Manning 저항 계수
    = LoadParameterValues(INPUT_FILE_PARAM_PATH);

% -------------------------------------------------------------------------
% 차후 LoadParameterValues 함수에 포함될 초기 입력값

% 1. 반복문 내 임시 세부 단위시간 설정과 관련된 변수의 계수와 지수
% (최적화된 값을 파악하기 어려워 여기서 일단 고정함)
basicManipulationRatio = 0.5; nt = 4;

%--------------------------------------------------------------------------

% 모의 결과를 저장하는 세부 디렉터리
mkdir(OUTPUT_DIR_PATH,OUTPUT_SUBDIR);
OUTPUT_SUBDIR_PATH = fullfile(OUTPUT_DIR_PATH,OUTPUT_SUBDIR);

% 출력 파일 경로 상수
OUTPUT_FILE_WEATHER_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_WEATHER);
OUTPUT_FILE_SEDTHICK_PATH ...`
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_SEDTHICK);
OUTPUT_FILE_BEDROCKELEV_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_BEDROCKELEV);
OUTPUT_FILE_dSEDTHICK_BYHILLSLOPE_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_dSEDTHICK_BYHILLSLOPE);
OUTPUT_FILE_CHANBEDSEDBUDGET_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_CHANBEDSEDBUDGET);
OUTPUT_FILE_dSEDTHICK_BYFLUVIAL_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_dSEDTHICK_BYFLUVIAL);
OUTPUT_FILE_dBEDROCKELEV_BYFLUVIAL_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_dBEDROCKELEV_BYFLUVIAL);
OUTPUT_FILE_dSEDTHICK_BYRAPIDMASS_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_dSEDTHICK_BYRAPIDMASS);
OUTPUT_FILE_dBEDROCKELEV_BYRAPIDMASS_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_dBEDROCKELEV_BYRAPIDMASS);
OUTPUT_FILE_LOG_PATH ...
    = fullfile(OUTPUT_SUBDIR_PATH,OUTPUT_FILE_LOG);

%--------------------------------------------------------------------------
% GPSSMain()과 다른 부분
% : read 모드로 파일을 엶
% : MakeInitialGeomorphology()를 생략함
% : mRows,nCols를 FID_LOG를 통해 추출함
%--------------------------------------------------------------------------

% 개별 파일을 열어둠: read 모드로 파일을 엶
FID_SEDTHICK = fopen(OUTPUT_FILE_SEDTHICK_PATH,'r');
FID_BEDROCKELEV = fopen(OUTPUT_FILE_BEDROCKELEV_PATH,'r');
FID_WEATHER = fopen(OUTPUT_FILE_WEATHER_PATH,'r');
FID_dSEDTHICK_BYHILLSLOPE = fopen(OUTPUT_FILE_dSEDTHICK_BYHILLSLOPE_PATH,'r');
FID_CHANBEDSEDBUDGET = fopen(OUTPUT_FILE_CHANBEDSEDBUDGET_PATH,'r');
FID_dSEDTHICK_BYFLUVIAL = fopen(OUTPUT_FILE_dSEDTHICK_BYFLUVIAL_PATH,'r');
FID_dBEDROCKELEV_BYFLUVIAL = fopen(OUTPUT_FILE_dBEDROCKELEV_BYFLUVIAL_PATH,'r');
FID_dSEDTHICK_BYRAPIDMASS = fopen(OUTPUT_FILE_dSEDTHICK_BYRAPIDMASS_PATH,'r');
FID_dBEDROCKELEV_BYRAPIDMASS = fopen(OUTPUT_FILE_dBEDROCKELEV_BYRAPIDMASS_PATH,'r');
FID_LOG = fopen(OUTPUT_FILE_LOG_PATH,'r');

% MakeInitialGeomorphology는 생략함

% mRows,nCols는 FID_LOG 파일을 통해 추출
mRows ... % 모델 (외곽 경계 포함) 영역 행 개수
    = fscanf(FID_LOG,'%i',1);
nCols ... % 모델 (외곽 경계 포함) 영역 열 개수
    = fscanf(FID_LOG,'%i',1);

%--------------------------------------------------------------------------
% GPSSMain()과 같은 부분
%--------------------------------------------------------------------------

% 상수 및 변수 초기화
Y_TOP_BND = 1;          % 모델 외곽 위 경계 Y 좌표값
Y_BOTTOM_BND = mRows;   % 모델 외곽 아래 경계 Y 좌표값
Y_INI = 2;              % 모델 영역 Y 시작 좌표값
Y_MAX = Y+1;            % 모델 영역 Y 마지막 좌표값

X_LEFT_BND = 1;         % 모델 외곽 좌 경계 X 좌표값
X_RIGHT_BND = nCols;    % 모델 외곽 우 경계 X 좌표값
X_INI = 2;              % 모델 영역 X 시작 좌표값
X_MAX = X+1;            % 모델 영역 X 마지막 좌표값

OUTER_BOUNDARY = true(mRows,nCols); % 모델 영역 외곽 경계
OUTER_BOUNDARY(Y_INI:Y_MAX,X_INI:X_MAX) = false;

CELL_AREA = dX * dX; % 셀 면적

QUARTER_PI = 0.785398163397448;     % pi * 0.25
HALF_PI = 1.57079632679490;         % pi * 0.5
ROOT2 = 1.41421356237310;           % sqrt(2)

DISTANCE_RATIO_TO_NBR = [1 ROOT2 1 ROOT2 1 ROOT2 1 ROOT2];

[arrayX ...             % 모델 (외곽 경계 포함) 영역 X 좌표 행렬
,arrayY] ...            % 모델 (외곽 경계 포함) 영역 Y 좌표 행렬
    = meshgrid(X_LEFT_BND:X_RIGHT_BND,Y_TOP_BND:Y_BOTTOM_BND);

% * 주의 : 접두사 's'는 (mRows*mCols) 보다 작은 Y*X 크기를 가지는 행렬
[sArrayX ...            % 모델 (외곽 경계 제외) 영역 X 좌표 행렬
,sArrayY] ...            % 모델 (외곽 경계 제외) 영역 Y 좌표 행렬
    = meshgrid(X_INI:X_MAX,Y_INI:Y_MAX);

% (무한 유향을 구하는 과정에서) facet을 구성하는 중앙 셀(e0) 색인 행렬
e0LinearIndicies ...
    = (arrayX-1) * mRows + arrayY;
% * 주의: 좌우 외곽 경계가 연결되었다면, 좌우 외곽 경계 색인을 수정함
if IS_LEFT_RIGHT_CONNECTED == true
    e0LinearIndicies(:,X_LEFT_BND) = e0LinearIndicies(:,X_MAX);
    e0LinearIndicies(:,X_RIGHT_BND) = e0LinearIndicies(:,X_INI);    
end
sE0LinearIndicies = (sArrayX-1) * mRows + sArrayY;

% (최대하부경사 유향을 구하는 과정에서) 8 방향 이웃 셀을 가리키는 3차원 색인 배열
s3IthNbrLinearIndicies = zeros(Y,X,8);

% * 주의: 순서는 동쪽에서  반 시계 방향.
ithNbrYOffset ... % 중앙 셀로 부터 8 방향 이웃 셀을 가리키기 위한 Y축 옵셋
    = [0 -1 -1 -1  0  1  1  1];
ithNbrXOffset ... % 중앙 셀로 부터 8 방향 이웃 셀을 가리키기 위한 X축 옵셋
    = [1  1  0 -1 -1 -1  0  1];

% facet을 구성하는 e1과 e2의 색인 배열 선언
s3E1LinearIndicies = zeros(Y,X,8);
s3E2LinearIndicies = zeros(Y,X,8);

% * 주의: 반 시계 방향이 절대 아님. Tarboton(1997)의 Figure 2와 Table 1 참고
ithFacetE1Offset ... % e0로부터 facet을 구성하는 e1을 가리키기 위한 옵셋
    = [ mRows   -1       -1       -mRows   ...
       -mRows    1        1        mRows  ];
ithFacetE2Offset ... % e0로부터 facet을 구성하는 e2를 가리키기 위한 옵셋
    = [ mRows-1  mRows-1 -mRows-1 -mRows-1 ...
       -mRows+1 -mRows+1  mRows+1  mRows+1];

% 8 방향 이웃 셀의 색인 및 8 방향 facet의 e1, e2 색인
for ithDir = 1:8
    
    % (동쪽에서 반 시계 방향으로)
    s3IthNbrLinearIndicies(:,:,ithDir) ...  % 각 방향의 이웃 셀 색인
        = e0LinearIndicies(sE0LinearIndicies ...
        + (ithNbrXOffset(ithDir) * mRows + ithNbrYOffset(ithDir)));

    % (동쪽에서 반 시계 방향으로 )
    s3E1LinearIndicies(:,:,ithDir) ...  % 각 facet의 e1 색인
        = e0LinearIndicies(sE0LinearIndicies + ithFacetE1Offset(ithDir));
    s3E2LinearIndicies(:,:,ithDir) ...  % 각 facet의 e2 색인
        = e0LinearIndicies(sE0LinearIndicies + ithFacetE2Offset(ithDir));

end

vectorY = reshape(sArrayY,[],1); % Y 좌표 행렬의 벡터
vectorX = reshape(sArrayX,[],1); % X 좌표 행렬의 벡터

SECPERYEAR = 31536000;          % = 365 * 24 * 60 * 60
FLOODED = 2;                    % flooded region 태그

dTAfterLastShallowLandslide = zeros(mRows,nCols); % 마지막 천부활동 이후 경과 시간
dTAfterLastBedrockLandslide = zeros(mRows,nCols); % 마지막 기반암활동 이후 경과 시간

% oldChanBedSed ...               % 이전 하도 내 하상 퇴적물 [m^3]
%     = zeros(mRows,nCols);    
% dChanBedSedPerDT ...            % 이전 하도 내 하상 퇴적물과의 차이 [m^3/dT]
%     = zeros(mRows,nCols);
chanBedSedBudgetPerDT ...       % 잔존 하상 퇴적물과 새로 구한 퇴적물과의 차이 [m^3/dT]
    = zeros(mRows,nCols);
remnantChanBedSed ...           % 잔존 하상 퇴적물 [m^3]
    = zeros(mRows,nCols);

%--------------------------------------------------------------------------
% 충적 하천에 의한 퇴적물 운반율 수식(Einstein-Brown)의 계수

% * 주의: Hortonian Overlandflow를 가정하였지만, 다른 수문 환경을 첨가할 예정
annualRunoff ...        % 연간 지표 유출량[m/year]
    = annualPrecipitation - annualEvapotranspiration;

g = 9.8;                % 중력 가속도 [m/s^2]
nu = 1.47 * 10^(-6);    % 수분의 동적 점성도 (kinematic viscosity) [m^2/s]
wGamma = 1000;          % 물 비중 [kgf/m^3]
wRho = 1000;            % 물 밀도 [kg/m^3]
fSGamma = fSRho;        % 퇴적물 비중 [kgf/m^3]
s = fSGamma / wGamma;   % 퇴적물 상대 밀도 []
F ...                   % 무차원 사립자 침강 속도 (Brown(1950),Yang(2003))
    = (2/3 + (36 * nu^2) / (g * fSD50^3 * (s-1)))^0.5 ...
     - ((36 * nu^2) / (g * fSD50^3 * (s-1)))^0.5;
kfa ...                 % 퇴적물 운반율 수식 계수 
    = (1 / (fSGamma * (1 - eta))) ... % [kg/m s] -> [m^2/s]
    * 40 * fSGamma * F * (g * (s-1) * fSD50^3)^0.5 ...
    * (1 / ((s-1) * fSD50))^3 * nA ^ 1.8;

%--------------------------------------------------------------------------
% 모의기간 동안 융기율의 공간적, 시간적 분포를 정의함

[meanUpliftRateSpatialDistribution ...  % (모의기간 평균) 연간 융기율의 공간적 분포
,upliftRateTemporalDistribution ...     % (모의기간) 연간 융기율의 시간적 분포
,meanUpliftRateAtUpliftAxis ...         % 융기축의 (모의기간 평균) 연간 융기율
,topBndElev] ...                        % 외곽 위 경계에서의 고도
    = DefineUpliftRateDistribution(Y,X,Y_INI,X_INI,Y_MAX,X_MAX,dX ...
    ,TIME_STEPS_NO,TOTAL_ACCUMULATED_UPLIFT,dT ...
    ,IS_TILTED_UPWARPING,UPLIFT_AXIS_DISTANCE_FROM_COAST ...
    ,TOP_BOUNDARY_ELEV_COND,Y_TOP_BND_FINAL_ELEV ...
    ,RAMP_ANGLE_TO_TOP ...
    ,UPLIFT_RATE_TEMPORAL_DISTRIBUTION_COND ...
    ,dUpliftRate,acceleratedUpliftPhaseNo,upliftRate0 ...
    ,waveArrivalTime,initUpliftRate);

%--------------------------------------------------------------------------
% GPSSMain()과 다른 부분
%--------------------------------------------------------------------------

% 2) 분석 figure 위치 및 크기 정의

% 그래프 보여주기 옵션 상수 정의
SHOW_GRAPH_YES = 1;
SHOW_GRAPH_NO = 2;

% (1) 분석시 그래프를 보여줄 경우, figure들의 위치와 핸들 정의
if SHOW_GRAPH == SHOW_GRAPH_YES

    % A. 모니터 위치 변수 관련 정의

    % 주모니터 상수 정의
    LEFT_MONITOR = 1;
    RIGHT_MONITOR = 2;
    
    % 주모니터의 위치 정의
    primaryMonitor = LEFT_MONITOR;
    secondaryMonitor = RIGHT_MONITOR;
    
    % (figure 배치를 위한) 모니터 분할
    leftMonWidthDivisionNo = 6;                 % 좌측 모니터 분할 수:열,행
    leftMonHeightDivisionNo = 3;
    rightMonWidthDivisionNo = 6;                % 우측 모니터 분할 수:열,행
    rightMonHeightDivisionNo = 3;    
    
    % figure 창 폭 설정
    % * 주의: figure 위치 조절시에 창 폭을 고려하지 않기 때문에 미리 제목 두께와
    %   창 옆의 폭을 파악함
    figSideBorderThick = 1;
    figHeaderBorderThick = 40;
    bothThick = figSideBorderThick + figHeaderBorderThick;
    
    % B. 모니터 위치 및 폭과 높이 파악
    monPosition = get(0,'MonitorPosition'); % 모니터 위치 정보 획득
    % * 참고: 듀얼 모니터일경우, 주모니터가 1째 행에 그리고 부모니터는 2째 행에
    %   관련 정보가 나타남.
    %   1열은 모니터 좌측 첫번째 화소의 위치, 2열은 아래 첫번째 화소의 위치,
    %   3열은 모니터 좌우폭, 4열은 모니터 위아래폭임. 단위 화소.
    % * 주의: 주모니터는 1열과 2열 모두 각각 1이 입력됨. 따라서 주모니터가
    %   우측에 있을 경우, 좌측 모니터의 좌측 첫번째 화소의 위치는 음의 값을 가짐
    %
    % * 예1: set(0,'Units','Normalized')을 하지 않은 경우
    % * 예1: 주모니터가 좌측(해상도: 1680x1050)이고, 부모니터(해상도:
    %   1024x768)가 우측에 위치할 경우
    %   (1025, 1, 2074, 1050; 1, 1, 1024, 768)
    % * 예2: 주모니터가 우측(해상도: 1024x768)이고, 부모니터(해상도:
    %   1680x1050)가 좌측에 위치할 경우
    %   (1, 1, 1680, 1050; -1023, 1, 0, 768)
    
    if primaryMonitor == LEFT_MONITOR
        
        % 좌측 모니터 위치
        leftMonLeftPos = 1;
        leftMonBottomPos = monPosition(primaryMonitor,2);   % 좌측 모니터 바닥 위치
        leftMonWidth = monPosition(primaryMonitor,3);       % 좌측 모니터 좌우 길이
        leftMonHeight = monPosition(primaryMonitor,4);      % 좌측 모니터 위아래 길이

        % 우측 모니터 위치
        rightMonLeftPos = monPosition(secondaryMonitor,1);  % 우측 모니터 좌측 첫번째 화소 위치    
        rightMonBottomPos = 1;                                 % 우측 모니터 바닥. * 주의: monPosition(secondaryMonitor,2)는 이상함
        rightMonWidth = monPosition(secondaryMonitor,3);    % 우측 모니터 좌우 길이
        % * 주의: 주모니터가 좌측이고 부모니터가 우측이면 좌측 모니터의 좌우 길이를
        %   빼야함
        rightMonWidth = rightMonWidth - leftMonWidth;
        rightMonHeight = monPosition(secondaryMonitor,4); % 우측 모니터 위아래 길이
        
    else % primaryMonitor == LEFT_MONITOR
        
        % 좌측 모니터 위치
        leftMonLeftPos = monPosition(secondaryMonitor,1);       % 좌측 모니터 좌측 첫번째 화소 위치 
        leftMonBottomPos = monPosition(secondaryMonitor,2);     % 좌측 모니터 바닥 위치
        leftMonWidth = - monPosition(secondaryMonitor,1);       % 좌측 모니터 좌우 길이
        leftMonHeight = monPosition(secondaryMonitor,4) - monPosition(secondaryMonitor,2);      % 좌측 모니터 위아래 길이

        % 우측 모니터 위치
        rightMonLeftPos = monPosition(primaryMonitor,1);  % 우측 모니터 좌측 첫번째 화소 위치    
        rightMonBottomPos = 1;                                 % 우측 모니터 바닥. * 주의: monPosition(secondaryMonitor,2)는 이상함
        rightMonWidth = monPosition(primaryMonitor,3);    % 우측 모니터 좌우 길이
        rightMonHeight = monPosition(primaryMonitor,4); % 우측 모니터 위아래 길이
        
       
    end

    % C. figure 위치 설정
    % * 참고: [모니터 좌측 경계에서부터,모니터 바닥 경계에서부터,좌우 길이,위아래 길이]
    % * 수정: 1) 가로 폭을 좁혀, figure 개수를 늘림. 2) 물질수지 등은 text 박스 표시
    
    % 좌측 모니터
    leftMonModifiedLeftPos ...             % 좌측 모니터 좌측 좌표
        = leftMonLeftPos + figSideBorderThick; 
    leftMonModifiedBottomPos ...           % 좌측 모니터 바닥 좌표
        = leftMonBottomPos + figSideBorderThick;
    leftMonBasicDividedWidth ...           % 좌측 모니터 분할된 좌우 길이
        = (leftMonWidth - leftMonWidthDivisionNo * 2 * figSideBorderThick) ...
        / leftMonWidthDivisionNo;    
    leftMonBasicDividedHeight ...       % 좌측 모니터 분할된 위아래 길이
        = (leftMonHeight - leftMonHeightDivisionNo * bothThick) ...
        / leftMonHeightDivisionNo;
    
    leftMonPos01 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 0) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 1 ...
        ,leftMonBasicDividedWidth * 3 ...
        ,leftMonBasicDividedHeight * 2];

    leftMonPos02 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 0) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 0 ...
        ,leftMonBasicDividedWidth * 1 ...
        ,leftMonBasicDividedHeight * 1];

    leftMonPos03 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 1) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 0 ...
        ,leftMonBasicDividedWidth * 1 ...
        ,leftMonBasicDividedHeight * 1];

    leftMonPos04 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 2) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 0 ...
        ,leftMonBasicDividedWidth * 1 ...
        ,leftMonBasicDividedHeight * 1];
    
    leftMonPos05 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 3) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 0 ...
        ,leftMonBasicDividedWidth * 1 ...
        ,leftMonBasicDividedHeight * 1];

    leftMonPos06 ...
        = [leftMonModifiedLeftPos + (leftMonBasicDividedWidth * 4) ...
        ,leftMonModifiedBottomPos + (leftMonBasicDividedHeight + bothThick) * 0 ...
        ,leftMonBasicDividedWidth * 1 ...
        ,leftMonBasicDividedHeight * 1];

    % 우측 모니터    
    rightMonModifiedLeftPos ...             % 우측 모니터 좌측 좌표
        = rightMonLeftPos + figSideBorderThick;
    rightMonModifiedBottomPos ...           % 우측 모니터 바닥 좌표
        = rightMonBottomPos + figSideBorderThick;       
    rightMonBasicDividedWidth ...           % 우측 모니터 분할된 좌우 길이
        = (rightMonWidth - rightMonWidthDivisionNo * 2 * figSideBorderThick) ... % 약간 줄임
        / rightMonWidthDivisionNo;
    rightMonBasicDividedHeight ...          % 우측 모니터 분할된 위아래 길이
        = (rightMonHeight - rightMonHeightDivisionNo * bothThick) ....
        / rightMonHeightDivisionNo;
    
    rightMonPos01 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 0) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos02 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 1) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos03 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 2) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos04 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 3) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos05 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 4) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos06 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 5)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 2 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos07 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 0)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos08 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 1)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos09 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 2)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos10 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 3)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos11 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 4)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos12 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 5)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 1 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos13 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 0)  ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos14 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 1) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos15 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 2) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos16 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 3) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    rightMonPos17 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 4) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];
    
    rightMonPos18 ...
        = [rightMonModifiedLeftPos + (rightMonBasicDividedWidth * 5) ...
        ,rightMonModifiedBottomPos + (rightMonBasicDividedHeight + bothThick) * 0 ...
        ,rightMonBasicDividedWidth * 1 ...
        ,rightMonBasicDividedHeight * 1];

    %--------------------------------------------------------------------------
    % 2) figure 핸들

    Hf_01 = figure(1);
    set(gcf,'Units','Pixel','Position',leftMonPos01,'MenuBar','none');
    Hf_02 = figure(2);
    set(gcf,'units','Pixel','position',leftMonPos02,'MenuBar','none');
    Hf_03 = figure(3);
    set(gcf,'units','Pixel','position',leftMonPos03,'MenuBar','none');
    Hf_04 = figure(4);
    set(gcf,'units','Pixel','position',leftMonPos04,'MenuBar','none');
    Hf_05 = figure(5);
    set(gcf,'units','Pixel','position',leftMonPos05,'MenuBar','none');
    Hf_06 = figure(6);
    set(gcf,'units','Pixel','position',leftMonPos06,'MenuBar','none');
    Hf_07 = figure(7);
    set(gcf,'units','Pixel','position',rightMonPos01,'MenuBar','none');
    Hf_08 = figure(8);
    set(gcf,'units','Pixel','position',rightMonPos02,'MenuBar','none');
    Hf_09 = figure(9);
    set(gcf,'units','Pixel','position',rightMonPos03,'MenuBar','none');
    Hf_10 = figure(10);
    set(gcf,'units','Pixel','position',rightMonPos04,'MenuBar','none');
    Hf_11 = figure(11);
    set(gcf,'units','Pixel','position',rightMonPos05,'MenuBar','none');
    Hf_12 = figure(12);
    set(gcf,'units','Pixel','position',rightMonPos06,'MenuBar','none');
    Hf_13 = figure(13);
    set(gcf,'units','Pixel','position',rightMonPos07,'MenuBar','none');
    Hf_14 = figure(14);
    set(gcf,'units','Pixel','position',rightMonPos08,'MenuBar','none');
    Hf_15 = figure(15);
    set(gcf,'units','Pixel','position',rightMonPos09,'MenuBar','none');
    Hf_16 = figure(16);
    set(gcf,'units','Pixel','position',rightMonPos10,'MenuBar','none');
    Hf_17 = figure(17);
    set(gcf,'units','Pixel','position',rightMonPos11,'MenuBar','none');
    Hf_18 = figure(18);
    set(gcf,'units','Pixel','position',rightMonPos12,'MenuBar','none');
    Hf_19 = figure(19);
    set(gcf,'units','Pixel','position',rightMonPos13,'MenuBar','none');
    Hf_20 = figure(20);
    set(gcf,'units','Pixel','position',rightMonPos14,'MenuBar','none');
    Hf_21 = figure(21);
    set(gcf,'units','Pixel','position',rightMonPos15,'MenuBar','none');
    Hf_22 = figure(22);
    set(gcf,'units','Pixel','position',rightMonPos16,'MenuBar','none');
    Hf_23 = figure(23);
    set(gcf,'units','Pixel','position',rightMonPos17,'MenuBar','none');
    Hf_24 = figure(24);
    set(gcf,'units','Pixel','position',rightMonPos18,'MenuBar','none');

end

%--------------------------------------------------------------------------
% 3) 결과 분석을 위한 변수 초기화

% 운반환경 분류 상수
ALLUVIAL_CHANNEL = 1;               % 충적 하도
BEDROCK_CHANNEL = 2;                % 기반암 하상 하도
BEDROCK_EXPOSED_HILLSLOPE = 3;      % 기반암이 노출된 사면
SOIL_MANTLED_HILLSLOPE = 4;         % 전토층으로 덮힌 사면

% 이웃 셀의 좌표를 구하기 위한 offset
% * 주의: 동쪽에 있는 이웃 셀부터 반시계 방향임
offsetY = [0; -1; -1; -1; 0; 1; 1; 1];
offsetX = [1; 1; 0; -1; -1; -1; 0; 1];

% * 주의: 좌우 경계가 연결되는 조건일 경우 offsetX 수정
if IS_LEFT_RIGHT_CONNECTED == true
    
    X_INI_OffsetX = offsetX;
    X_INI_OffsetX(4:6) = X - 1;

    X_MAX_OffsetX = offsetX;
    X_MAX_OffsetX(1:2) = -(X - 1);
    X_MAX_OffsetX(8) = -(X - 1);
    
end

distanceY = Y * dX;                 % Y축 거리
distanceX = X * dX;                 % X축 거리

[arrayXForGraph,arrayYForGraph] ...
    = meshgrid(0.5*dX:dX:distanceX-0.5*dX,0.5*dX:dX:distanceY-0.5*dX);

% 파일의 첫 결과의 GPSS 실행 횟수 정의
% * 주의: GPSS 구동이 중단된 것을 분석하는지 확인함
if INIT_TIME_STEP_NO ~= 1    
    % 연속되는 것이라면, 가장 마지막 실행 결과에서 한 단위 큰 값을 입력함
    initIthStep = (INIT_TIME_STEP_NO - 1) / WRITE_INTERVAL + 1;    
else    
    % 연속되는 것이 아니라면 1로 정의
    initIthStep = 1;    
end

% 파일의 마지막 결과의 GPSS 실행 횟수 정의
endStep ...                         % 결과가 파일에 기록된 횟수
    = floor(TIME_STEPS_NO/WRITE_INTERVAL * achievedRatio);


% 그래프 보여주기 횟수 및 주요 2차원 변수 저장 횟수 관련 변수
totalGraphShowTimesNo ...                            % 그래프를 보여주는 총 횟수
    = ceil(endStep / GRAPH_INTERVAL);
ithGraph = 0;                                        % 현재까지 보여준 그래프 횟수
dGraphShowTime = WRITE_INTERVAL * GRAPH_INTERVAL;    % 그래프 갱신 시간

% 주요 변수를 저장(파일->mat)하는 간격 조정
% * 주의: 두 가지 간격으로 저장함. 2차원 변수는 큰 간격으로, 1차원 (시계열)
%   변수는 작은 간격으로 totalGraphShowTimesNo과 동일하게 저장함
% * 주의: 추출 간격이 그래프 보여주기 횟수보다 크면 보여주기 횟수를 추출간격으로
%   대체함
if EXTRACT_INTERVAL > totalGraphShowTimesNo
    EXTRACT_INTERVAL = totalGraphShowTimesNo;
end

% 주요 2차원 변수를 저장하는 총 횟수
totalExtractTimesNo = floor(totalGraphShowTimesNo / EXTRACT_INTERVAL);

ithExtractTime = 0;                 % mat 파일 기록을 위한 색인 초기화

% 영동 유역 횡단면도 분석 지점 정의
upperCrossProfileY = 45;
middleCrossProfileY = 70;
lowerCrossProfileY = 95;
upperCrossProfileZone = upperCrossProfileY-2:upperCrossProfileY+2;
middleCrossProfileZone = middleCrossProfileY-2:middleCrossProfileY+2;
lowerCrossProfileZone = lowerCrossProfileY-2:lowerCrossProfileY+2;

% mat 파일에 기록할 주요 변수
% 2 차원
extSedimentThick = zeros(mRows,nCols,totalExtractTimesNo+1);
extBedrockElev = zeros(mRows,nCols,totalExtractTimesNo+1);
extWeatheringProduct = zeros(mRows,nCols,totalExtractTimesNo);
extDSedThickByHillslopePerDT = zeros(mRows,nCols,totalExtractTimesNo);
extDSedThickByRapidMassPerDT = zeros(mRows,nCols,totalExtractTimesNo);
extDBedrockElevByRapidMassPerDT = zeros(mRows,nCols,totalExtractTimesNo);
extDSedThickByFluvialPerDT = zeros(mRows,nCols,totalExtractTimesNo);
extDBedrockElevByFluvialPerDT = zeros(mRows,nCols,totalExtractTimesNo);
extChanBedSedBudget = zeros(mRows,nCols,totalExtractTimesNo);
extUpslopeArea = zeros(mRows,nCols,totalExtractTimesNo);
extTransportMode = zeros(mRows,nCols,totalExtractTimesNo);
extFacetFlowSlope = zeros(mRows,nCols,totalExtractTimesNo);
% 1차원
% * 주의: 그래프로 화면에 보여줄 수 없어서 저장함
extEastDrainageDensity = zeros(totalGraphShowTimesNo,1);
extWestDrainageDensity = zeros(totalGraphShowTimesNo,1);
extEastSoilMantledHillRatio = zeros(totalGraphShowTimesNo,1);
extWestSoilMantledHillRatio = zeros(totalGraphShowTimesNo,1);
extEastBedrockExposedHillRatio = zeros(totalGraphShowTimesNo,1);
extWestBedrockExposedHillRatio = zeros(totalGraphShowTimesNo,1);
extEastAlluvialChanRatio = zeros(totalGraphShowTimesNo,1);
extWestAlluvialChanRatio = zeros(totalGraphShowTimesNo,1);
extEastBedrockChanRatio = zeros(totalGraphShowTimesNo,1);
extWestBedrockChanRatio = zeros(totalGraphShowTimesNo,1);
extEastRapidMassFreq = zeros(totalGraphShowTimesNo,1);
extWestRapidMassFreq = zeros(totalGraphShowTimesNo,1);
extEastUpperHillRegolithThick = zeros(totalGraphShowTimesNo,1);
extEastMiddleHillRegolithThick = zeros(totalGraphShowTimesNo,1);
extEastBottomHillRegolithThick = zeros(totalGraphShowTimesNo,1);
extEastUpperChannelSedThick = zeros(totalGraphShowTimesNo,1);
extEastMiddleChannelSedThick = zeros(totalGraphShowTimesNo,1);
extEastBottomChannelSedThick = zeros(totalGraphShowTimesNo,1);
extEastUpperHillDSedThick = zeros(totalGraphShowTimesNo,1);
extEastMiddleHillDSedThick = zeros(totalGraphShowTimesNo,1);
extEastLowerHillDSedThick = zeros(totalGraphShowTimesNo,1);
extEastUpperChannelDBedrockElev = zeros(totalGraphShowTimesNo,1);
extEastMiddleChannelDBedrockElev = zeros(totalGraphShowTimesNo,1);
extEastLowerChannelDBedrockElev = zeros(totalGraphShowTimesNo,1);
extEastUpperChannelDSedThick = zeros(totalGraphShowTimesNo,1);
extEastMiddleChannelDSedThick = zeros(totalGraphShowTimesNo,1);
extEastLowerChannelDSedThick = zeros(totalGraphShowTimesNo,1);
extEastUpperUpliftedHeight = zeros(totalGraphShowTimesNo,1);
extEastMiddleUpliftedHeight = zeros(totalGraphShowTimesNo,1);
extEastLowerUpliftedHeight = zeros(totalGraphShowTimesNo,1);
extEastUpperChannelWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastMiddleChannelWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastLowerChannelWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastUpperHillslopeWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastMiddleHillslopeWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastLowerHillslopeWeatheringRate = zeros(totalGraphShowTimesNo,1);
extEastUpperFluvialTransportCapacity = zeros(totalGraphShowTimesNo,1);
extEastMiddleFluvialTransportCapacity = zeros(totalGraphShowTimesNo,1);
extEastLowerFluvialTransportCapacity = zeros(totalGraphShowTimesNo,1);

% 융기율 누적 변수
cumsumUpliftRate = cumsum(upliftRateTemporalDistribution);

% 횡단상 변화 그래프를 위한 축 설정 관련 변수 초기화
oldBiggestY = 0;
axisX = 0.5*dX:dX:distanceX-0.5*dX;

% 반복문 내 변수 선언
L = ones(mRows,nCols) * 9;                              % 외곽 경계에는 0이 아닌 임의의 값을 넣음
eastMeanElev = zeros(totalGraphShowTimesNo,1);                  % 영동 유역분지 평균 고도
eastMeanSlope = zeros(totalGraphShowTimesNo,1);                 % 영동 유역분지 평균 경사
eastMeanSedimentThick = zeros(totalGraphShowTimesNo,1);         % 영동 유역분지 평균 퇴적층 두께
eastMeanWeatheringProduct = zeros(totalGraphShowTimesNo,1);     % 영동 유역분지 평균 풍화율
eastMeanErosionRate = zeros(totalGraphShowTimesNo,1);           % 영동 유역분지 평균 침식율
eastMeanUpliftedHeight = zeros(totalGraphShowTimesNo,1);        % 영동 유역분지 평균 융기율
westMeanElev = zeros(totalGraphShowTimesNo,1);                  % 영서 유역분지 평균 고도
westMeanSlope = zeros(totalGraphShowTimesNo,1);                 % 영서 유역분지 평균 경사
westMeanSedimentThick = zeros(totalGraphShowTimesNo,1);         % 영서 유역분지 평균 퇴적층 두께
westMeanWeatheringProduct = zeros(totalGraphShowTimesNo,1);     % 영서 유역분지 평균 풍화율
westMeanErosionRate = zeros(totalGraphShowTimesNo,1);           % 영서 유역분지 평균 침식율
westMeanUpliftedHeight = zeros(totalGraphShowTimesNo,1);        % 영서 유역분지 평균 융기율
upliftedHeight = zeros(mRows,nCols);                    % 단위시간 융기율 [m/dT]

%==========================================================================
% 2. 주요 분석 

% 1) 예비 작업

% (1) 초기 퇴적층 두께와 기반암 고도 읽음
% * 주의: 이는 초기 지형 및 초기 퇴적층 두께를 결과 파일에 출력하기 때문임
initSedThick = fscanf(FID_SEDTHICK,'%f',[mRows,nCols]);
initBedrockElev = fscanf(FID_BEDROCKELEV,'%f',[mRows,nCols]);

% 초기 기반암고도와 퇴적층 두께를 기록함
extSedimentThick(:,:,1) = initSedThick;
extBedrockElev(:,:,1) = initBedrockElev;

% (2) 그래프 출력 시작 지점 정의
startedStepNo = startedTimeStepNo / WRITE_INTERVAL;

% 2) 파일에서 i번째 모의결과를 읽고 이를 그래프로 표현하고 주요 변수는 일정
%    간격으로 저장함
for ithStep = initIthStep:endStep
    
    fprintf('%i\n',ithStep); % 실행 횟수 출력
    
    % (1) i번째 결과를 각 파일에서 읽음
    
    % * 주의: 파일에 기록된 퇴적층 두께 및 기반암 고도는 GPSSMain()에서 AdjustBoundary,
    %   Uplift 함수가 반영되었지만 외적 작용은 반영되지 않은 시점의 것임
    sedimentThick ...                   % (외적 작용 이전) 퇴적층 두께
        = fscanf(FID_SEDTHICK,'%f',[mRows,nCols]);
    
    bedrockElev ...                     % (외적 작용 이전) 기반암 고도
        = fscanf(FID_BEDROCKELEV,'%f',[mRows,nCols]);
    
    weatheringProduct ...               % 풍화율 [m/dT]
        = fscanf(FID_WEATHER,'%f',[mRows,nCols]);
    
    dSedThickByHillslopePerDT ...       % 사면작용에 의한 퇴적층 두께 변화율 [m^3/m^2 dT]
        = fscanf(FID_dSEDTHICK_BYHILLSLOPE,'%f',[mRows,nCols]);
    
    dSedThickByRapidMassPerDT ... % 빠른 사면작용에 의한 퇴적층 두께 변화율 [m^3/m^2 dT]
        = fscanf(FID_dSEDTHICK_BYRAPIDMASS,'%f',[mRows,nCols]);
    
    dBedrockElevByRapidMassPerDT ... % 빠른 사면작용에 의한 기반암 고도 변화율 [m^3/m^2 dT]
        = fscanf(FID_dBEDROCKELEV_BYRAPIDMASS,'%f',[mRows,nCols]);
    
    dSedThickByFluvialPerDT ...         % 하천작용에 의한 퇴적물 두께 변화율 [m^3/m^2 dT]
        = fscanf(FID_dSEDTHICK_BYFLUVIAL,'%f',[mRows,nCols]);
    
    dBedrockElevByFluvialPerDT ...      % 하천작용에 의한 기반암 고도 변화율[m^3/m^2 dT]
        = fscanf(FID_dBEDROCKELEV_BYFLUVIAL,'%f',[mRows,nCols]);
    
    chanBedSedBudget ...                % 하도 내 하상 퇴적물 물질 수지 [m^3/dT]
        = fscanf(FID_CHANBEDSEDBUDGET,'%f',[mRows,nCols]);
    
    % (2) [그래프] i번째 결과를 보여준다.
    if mod(ithStep,GRAPH_INTERVAL) == 0 ...
        && floor(ithStep/GRAPH_INTERVAL) > 0 && ithStep >= startedStepNo
        
    
        % A. 그래프 및 timeStep 관련 변수 정의
        ithTimeStep = ithStep * WRITE_INTERVAL;     % TIME_STEP_NO
        simulatingTime = ithTimeStep * dT;          % 만제유량 재현기간을 고려한 년도 [yr]
        ithGraph = ithGraph + 1;                    % 그래프 기록 횟수
        
        % (모의기간 전체 결과를 보여주는 그래프를 위한) 시작 년도 기록
        if ithGraph == 1
            firstGraphShowTime = ithTimeStep * dT;
        end
        
        elev = bedrockElev + sedimentThick;         % 고도 갱신            
        
        upliftedHeightPerDT ...                     % 융기율 분포 [m/dT]
            = meanUpliftRateSpatialDistribution(Y_INI:Y_MAX,X_INI:X_MAX) ...
            / meanUpliftRateAtUpliftAxis ...
            * upliftRateTemporalDistribution(ithTimeStep);        
        
        %------------------------------------------------------------------
        % B. i번째 (3차원) DEM
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_01);

        surf(arrayYForGraph,arrayXForGraph,elev(Y_INI:Y_MAX,X_INI:X_MAX))
        % meshz(arrayYForGraph,arrayXForGraph,elev(Y_INI:Y_MAX,X_INI:X_MAX))        

        view(25,30)            % 그래프 각도 조정

        grid(gca,'on')        
        set(gca,'DataAspectRatio',[1 1 0.25],'ZLim',[0 1500])
        endYAxisDistance = 30;
        set(gca,'YTick',0:endYAxisDistance/6:endYAxisDistance ...
            ,'YTickLabel',{'30 Km','','20','','10','','0'} ...
            ,'XTick',[] ...
            ,'XTickLabel',[])
        
        shading interp
        
        colormap(demcmap(elev(Y_INI:Y_MAX,X_INI:X_MAX)))        
        colorbar
        
        tmpTitle = [int2str(simulatingTime) 'th Elevation'];
        title(tmpTitle)        
        
        end
        
        %------------------------------------------------------------------
        % C.i번째 고도 등고선
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_02);
        
%         contourNo = 16;                             % 등고선 개수 설정
        % 모의기간 최대,최소 고도를 알 경우
%         contourNo = ceil(((max(max(elev(Y_INI:Y_MAX,X_INI:X_MAX))) ...
%             - min(min(elev(Y_INI:Y_MAX,X_INI:X_MAX)))) * contourNo) ...
%             / diffBtwMostMaxMin);
        
%         contourf(arrayXForGraph,arrayYForGraph ...  % 등고선도
%             ,elev(Y_INI:Y_MAX,X_INI:X_MAX),contourNo,'DisplayName','elev');        

%         if max(max(elev(Y_INI:Y_MAX,X_INI:X_MAX))) > 1
%           contourcmap(1,'jet','colorbar','on');        
%         end
%         colorbar   
        
        imshow(elev(Y_INI:Y_MAX,X_INI:X_MAX),[],'InitialMagnification','fit')
        colormap jet
        set(gca,'YDir','reverse')                   % Y축 방향을 반대로
        set(gca,'DataAspectRatio',[1 1 1]);         % 각 축 동일한 크기로 설정
        colorbar;            
        
        tmpTitle = [int2str(simulatingTime) 'th Elevation'];
        title(tmpTitle);       
        
        end
        
        %------------------------------------------------------------------
        % D. i번째 퇴적층 두께
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % 사면 셀에 사면물질이동에 의한 고도 변화만 있을 경우
        % * 주의: 하천이 시작하는 셀의 인접 사면은 퇴적물 유입량이 매우 크지만
        %   사면작용에 의한 유출량은 매우 적어서, 퇴적층 두께가 매우 높은 경향이
        %   관찰됨. 모의기간 후반부로 갈수록(즉 하천을 포함하는 셀이 많아질수록)
        %   이런 경향은 줄어들 것으로 예상됨. 하지만 이로 인해 퇴적층의 공간적
        %   분포를 관찰하기가 쉽지 않음. 따라서 평균을 중심으로 표준편차의
        %   3배까지만을 범례로 삼음
        % => 현재는 사면 셀에도 overland flow erosion을 고려하기 때문에 생략함
        
        % mu = mean2(sedimentThick(Y_INI:Y_MAX,X_INI:X_MAX));
        % sigma = std2(sedimentThick(Y_INI:Y_MAX,X_INI:X_MAX));
        
        % if mu - sigma*3 < 0
        %     minY = 0;
        % else
        %     minY = mu - sigma*3;
        % end
        
        figure(Hf_03);
        
        imagesc([0.5*dX dX distanceX-0.5*dX] ...    % imagesc 그래프
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,sedimentThick(Y_INI:Y_MAX,X_INI:X_MAX))
        
        % => 현재는 사면 셀에도 overland flow erosion을 고려하기 때문에 CLim을
        %    생략함
        % set(gca,'DataAspectRatio',[1 1 1],'CLim',[minY, mu + sigma*3])
        set(gca,'DataAspectRatio',[1 1 1])
        
        colorbar
        
        tmpTitle = [int2str(simulatingTime) 'th Sediment Thickness'];
        title(tmpTitle)
       
        end
        
        %------------------------------------------------------------------
        % E. i번째 경사
        
        % A) 무한 유향 알고리듬을 이용한 유향과 경사
        [facetFlowDirection ...     % 유향
        ,facetFlowSlope ...         % 경사
        ,e1LinearIndicies ...       % 다음 셀(e1) 색인
        ,e2LinearIndicies ...       % 다음 셀(e2) 색인
        ,outputFluxRatioToE1 ...    % 다음 셀(e1)로의 유입율
        ,outputFluxRatioToE2] ...   % 다음 셀(e2)로의 유입율
            = CalcInfinitiveFlow(mRows,nCols,Y,X,Y_INI,Y_MAX,X_INI,X_MAX ...
            ,QUARTER_PI,HALF_PI,elev,dX ...
            ,sE0LinearIndicies,s3E1LinearIndicies,s3E2LinearIndicies);
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % B) i번째 경사
        figure(Hf_04);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,facetFlowSlope(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th Gradient'];
        title(tmpTitle)
        
        %------------------------------------------------------------------
        % F. i번째 풍화율
        
        figure(Hf_05);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,weatheringProduct(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th Weathering Product'];
        title(tmpTitle)
        
        %------------------------------------------------------------------
        % G. i번째 사면작용에 의한 퇴적층 두께 변화율
        
        figure(Hf_06);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,dSedThickByHillslopePerDT(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th dSedThick By Slow Mass'];
        title(tmpTitle)
        
        %------------------------------------------------------------------
        % H. i번째 빠른 사면작용에 의한 퇴적층 두께 변화율
        
        figure(Hf_07);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,dSedThickByRapidMassPerDT(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th dSedThick By Rapid Mass'];
        title(tmpTitle)
        
        %------------------------------------------------------------------
        % I. i번째 빠른 사면작용에 의한 기반암 고도 변화율
        
        figure(Hf_08);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,dBedrockElevByRapidMassPerDT(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th dBedrockElev By Rapid Mass'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % J. i번째 flooded region 및 만제유량
        
        % A) 최대 하부 경사 유향 알고리듬을 이용한 유향과 경사
        [steepestDescentSlope ...   % 경사
        ,slopeAllNbr ...            % 8개 이웃 셀과의 경사
        ,SDSFlowDirection ...       % 유향
        ,SDSNbrY ...                % 다음 셀 Y 좌표값
        ,SDSNbrX] ...               % 다음 셀 X 좌표값
            = CalcSDSFlow(mRows,nCols,Y,X,Y_INI,Y_MAX,X_INI,X_MAX ...
            ,Y_TOP_BND,Y_BOTTOM_BND,X_LEFT_BND,X_RIGHT_BND ...
            ,QUARTER_PI,DISTANCE_RATIO_TO_NBR,elev,dX ...
            ,IS_LEFT_RIGHT_CONNECTED ...
            ,ithNbrYOffset,ithNbrXOffset ...
            ,sE0LinearIndicies,s3IthNbrLinearIndicies);
        
        % B) 유향이 정의되지 않은 셀에 유향을 정의함
        % * sink에 유향을 부여하고, flooded region에 유향을 재설정함
        [flood ...                      % flooded region
        ,SDSNbrY ...                    % 수정된 다음 셀의 Y 좌표값
        ,SDSNbrX ...                    % 수정된 다음 셀의 X 좌표값
        ,SDSFlowDirection ...           % 수정된 (최대하부경사 유향 알고리듬의) 유향
        ,steepestDescentSlope ...       % 수정된 (최대하부경사 유향 알고리듬의) 경사
        ,integratedSlope ...            % 수정된 (무한 유향 알고리듬) 경사
        ,floodedRegionIndex ...         % flooded region 색인
        ,floodedRegionCellsNo ...       % 각 flooded region 구성 셀 개수
        ,floodedRegionLocalDepth ...    % flooded region 고도와 유출구 고도와의 차이
        ,floodedRegionTotalDepth ...    % local depth 총 합
        ,floodedRegionStorageVolume] ...% flooded region 총 저장량
            = ProcessSink(mRows,nCols,X_INI,X_MAX ...
            ,Y_TOP_BND,Y_BOTTOM_BND,X_LEFT_BND,X_RIGHT_BND,QUARTER_PI,CELL_AREA ...
            ,elev,ithNbrYOffset,ithNbrXOffset ...
            ,OUTER_BOUNDARY,IS_LEFT_RIGHT_CONNECTED ...
            ,slopeAllNbr,steepestDescentSlope ...
            ,facetFlowSlope,SDSNbrY,SDSNbrX,SDSFlowDirection);
        
        % C) flooded region 그래프
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_09);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,flood(Y_INI:Y_MAX,X_INI:X_MAX))
        set(gca,'DataAspectRatio',[1 1 1],'CLim',[0 2])        
        colormap(jet(3))
        labels = {'Unflooded','Sink','Flooded'};
        lcolorbar(labels,'fontweight','bold')       
        tmpTitle = [int2str(simulatingTime) 'th Flooded Region'];
        title(tmpTitle)
        
        end
        
        % D) 연간 유량[m^3/dT]

        % a. 셀들을 고도 순으로 정렬
        elevForSorting = elev;

        % b. flooded region을 제외함
        % * 원리 : 제외하는 셀의 고도값에는 - inf를 입력함
        elevForSorting(flood == FLOODED) = - inf;

        % c. 높은 고도 순으로 정렬하고 이의 Y,X 좌표값을 구함
        vectorElev = reshape(elevForSorting(Y_INI:Y_MAX,X_INI:X_MAX),[],1);
        sortedYXElevForUpstreamFlow = [vectorY,vectorX,vectorElev];
        sortedYXElevForUpstreamFlow = sortrows(sortedYXElevForUpstreamFlow,-3);

        % d. AccumulateUpstreamFlow 함수의 대상 셀 수
        consideringCellsNoForUpstreamFlow = find(vectorElev > - inf);
        consideringCellsNoForUpstreamFlow ...
            = size(consideringCellsNoForUpstreamFlow,1);

        % e. 연간유량 [m^3/dT]
        [annualDischarge1 ...   % 연간유량 [m^3/dT]
        ,isOverflowing] ...     % flooded region 저수량 초과 여부 태그
            = AccumulateUpstreamFlow(mRows,nCols ...
            ,Y_TOP_BND,Y_BOTTOM_BND,X_LEFT_BND,X_RIGHT_BND,CELL_AREA ...
            ,sortedYXElevForUpstreamFlow ...
            ,consideringCellsNoForUpstreamFlow ...
            ,OUTER_BOUNDARY,annualRunoff ...
            ,flood,floodedRegionCellsNo ...
            ,floodedRegionStorageVolume,floodedRegionIndex ...
            ,facetFlowDirection,e1LinearIndicies,e2LinearIndicies ...
            ,outputFluxRatioToE1,outputFluxRatioToE2,SDSNbrY,SDSNbrX);    

        % E) 만제유량

        % a. 연 평균유량 [m^3/s]
        meanDischarge = annualDischarge1 / SECPERYEAR;

        % b. 만제유량 [m^3/s]
        bankfullDischarge = kqb * meanDischarge .^ mqb;
        
        % F) 만제유량 그래프
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        figure(Hf_10);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,log10(bankfullDischarge(Y_INI:Y_MAX,X_INI:X_MAX)))
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th Bankfull Discharge(log10)'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % K. i번째 하천작용에 의한 퇴적층 두께 변화율
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_11);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,dSedThickByFluvialPerDT(Y_INI:Y_MAX,X_INI:X_MAX))
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        
        % * 주의: 평균을 상회하는 값들이 존재해서, 중간값의 경향을 파악하기 위해
        %   표준편차 3배 범위로 그래프를 표현함
        mu = mean2(dSedThickByFluvialPerDT(Y_INI:Y_MAX,X_INI:X_MAX));
        sigma = std2(dSedThickByFluvialPerDT(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'CLim',[mu - sigma*3, mu + sigma*3])
        
        tmpTitle = [int2str(simulatingTime) 'th dSedThick By Fluvial'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % L. i번째 하천작용에 의한 기반암 고도 변화율
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        figure(Hf_12);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,dBedrockElevByFluvialPerDT(Y_INI:Y_MAX,X_INI:X_MAX))
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th dBedrockElev By Fluvial'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % M. i번째 물질운반환경 분류
        
        % (A) 물질운반환경 변수 초기화
        transportMode = zeros(mRows,nCols);         % 0으로 초기화
        
        % (B) 사면 셀과 하천 포함 셀을 구분함
        upslopeArea = annualDischarge1 ./ annualRunoff; % 유역면적: [m^3/yr]/[m/yr]
        
        channel ...                         % 하천 시작 임계치를 넘은 셀
            = ((upslopeArea .* integratedSlope .^ 2 >= channelInitiation) ...
            & (integratedSlope ~= -inf)) ... % 초기 경사값은 제외함
            | (upslopeArea / CELL_AREA >= criticalUpslopeCellsNo) ...
            | (flood == FLOODED);
        
        hillslope = ~channel;               % 사면 셀
        
        % (C) 사면 분류        
        transportMode(hillslope) ...        % 전토층으로 덮힌 사면
            = SOIL_MANTLED_HILLSLOPE;
        
        bedrockExposedHillslope = hillslope & ...   % 기반암으로 노출된 사면
            (sedimentThick < ...
            - (dSedThickByHillslopePerDT + dSedThickByFluvialPerDT) );
        
        transportMode(bedrockExposedHillslope) ...
            = BEDROCK_EXPOSED_HILLSLOPE;    
        
        % (B) 하도 분류            
        upslopeArea = annualDischarge1 ./ annualRunoff; % 유역면적: [m^3/yr]/[m/yr]

        transportMode(channel) = ALLUVIAL_CHANNEL;
        
        bedrockChannel = channel & (dBedrockElevByFluvialPerDT < 0);        
        transportMode(bedrockChannel) = BEDROCK_CHANNEL;
        
        % (C) 물질운반환경 분류 비율
        soilMantledHill = transportMode == SOIL_MANTLED_HILLSLOPE;
        soilMantledHillRatio = sum(soilMantledHill(:)) / (Y*X);
        
        bedrockExposedHill = transportMode == BEDROCK_EXPOSED_HILLSLOPE;
        bedrockExposedHillRatio = sum(bedrockExposedHill(:)) / (Y*X);
        
        alluvialChan = transportMode == ALLUVIAL_CHANNEL;
        alluvialChanRatio = sum(alluvialChan(:)) / (Y*X);
        
        bedrockChan = transportMode == BEDROCK_CHANNEL;
        bedrockChanRatio = sum(bedrockChan(:)) / (Y*X);
                
        % (D) 물질운반환경 분류 그래프        
        if SHOW_GRAPH == SHOW_GRAPH_YES   
            
        % a. 외곽경계 조건 설정
        % * 주의: 물질운반환경이 4가지가 아닐 경우, 범례 색깔과 실제 그래프의
        %   색깔과 다를 수 있기 때문에 외곽 경계에 각 값을 대입함
        transportMode(Y_TOP_BND,X_LEFT_BND) = SOIL_MANTLED_HILLSLOPE;
        transportMode(Y_BOTTOM_BND,X_LEFT_BND) = BEDROCK_EXPOSED_HILLSLOPE;
        transportMode(Y_TOP_BND,X_RIGHT_BND) = ALLUVIAL_CHANNEL;
        transportMode(Y_BOTTOM_BND,X_RIGHT_BND) = BEDROCK_CHANNEL;
        
        % b. 그래프
        figure(Hf_13);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,transportMode(Y_INI:Y_MAX,X_INI:X_MAX))
        set(gca,'DataAspectRatio',[1 1 1])

        colormap(jet(4))
        labels = {'Bedrock Channel','Alluvial Channel' ...
            ,'Bedrock Exposed Hillslope','Soil-mantled Hillslope'};
        
        lcolorbar(labels,'fontweight','bold')
        tmpTitle = [int2str(simulatingTime) 'th Transport Mode' ...
            '(' int2str(round(soilMantledHillRatio * 100)) '/' ...
            int2str(round(bedrockExposedHillRatio * 100)) '/' ...
            int2str(round(alluvialChanRatio * 100)) '/' ...
            int2str(round(bedrockChanRatio * 100)) ')'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % N. 누적 침식량
        
        % (A) 누적 융기량
        % * 주의: 초기 지형을 반영하여해야 올바른 누적 침식량을 구함
        accumulatedUpliftedHeight = zeros(mRows,nCols);
        accumulatedUpliftedHeight(Y_INI:Y_MAX,X_INI:X_MAX) ...
            = (meanUpliftRateSpatialDistribution(Y_INI:Y_MAX,X_INI:X_MAX) ...
            ./ meanUpliftRateAtUpliftAxis) ...
            * cumsumUpliftRate(ithTimeStep) ...
            + initBedrockElev(Y_INI:Y_MAX,X_INI:X_MAX) ...
            + initSedThick(Y_INI:Y_MAX,X_INI:X_MAX);
        
        % (B) 누적 침식량
        accumulatedErosionRate = zeros(mRows,nCols);
        accumulatedErosionRate(Y_INI:Y_MAX,X_INI:X_MAX) ...
            = accumulatedUpliftedHeight(Y_INI:Y_MAX,X_INI:X_MAX)...
            - elev(Y_INI:Y_MAX,X_INI:X_MAX);
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_14);
        set(gcf,'MenuBar','none')
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,accumulatedErosionRate(Y_INI:Y_MAX,X_INI:X_MAX))
        colorbar
        set(gca,'DataAspectRatio',[1 1 1])
        
        tmpTitle = [int2str(simulatingTime) 'th Acc Erosion Rate'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % O. Topographic Position Index
        filterSize = 3;                     % 필터 크기 
        
        % 좌우가 연결되었다면 좌우 외곽경계의 고도를 조정함
        
        % (필터 크기에 맞춘)좌우 외곽경계로 추가해야할 열 개수
        boundMarginColsNo = filterSize - 1;
        
        modifiedDEM = zeros(mRows,nCols+boundMarginColsNo*2);
        modifiedDEM(:,X_LEFT_BND+boundMarginColsNo:X_RIGHT_BND+boundMarginColsNo) = elev;
        
        % 좌우 외곽경계 고도 조정
        modifiedDEM(:,X_RIGHT_BND+boundMarginColsNo:X_RIGHT_BND+boundMarginColsNo*2) ...
            = modifiedDEM(:,X_INI+boundMarginColsNo:X_INI+boundMarginColsNo*2);
        modifiedDEM(:,X_LEFT_BND:X_LEFT_BND+boundMarginColsNo) ...
            = modifiedDEM(:,X_MAX:X_MAX+boundMarginColsNo);
        
        % 상하 외곽경계 고도 조정
        modifiedDEM(Y_TOP_BND,:) = modifiedDEM(Y_INI,:);
        modifiedDEM(Y_BOTTOM_BND,:) = modifiedDEM(Y_MAX,:);
        
        diskFilter = fspecial('disk',filterSize);

        smoothedDEMDisk = imfilter(modifiedDEM,diskFilter);

        diffElevDisk = smoothedDEMDisk - modifiedDEM;
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        figure(Hf_15);
        set(gcf,'MenuBar','none')
        imagesc(diffElevDisk(Y_INI:Y_MAX ...
            ,X_INI+boundMarginColsNo:X_MAX+boundMarginColsNo))
        colorbar
        
        % * 주의: 외곽경계 영향으로 서쪽 경계의 값이 매우 작음
        maxDiffElev = max(max(diffElevDisk(Y_INI:Y_MAX ...
            ,X_INI+boundMarginColsNo:X_MAX+boundMarginColsNo)));
        set(gca,'CLim',[-maxDiffElev maxDiffElev])
        
        set(gca,'DataAspectRatio',[1 1 1])
        
        tmpTitle = [int2str(simulatingTime) 'th TPI'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % P. 영동과 영서지역 분수계 파악하기
        % * 경동성 요곡 지반융기운동을 모의할 경우

        % (A) 모델 영역 추출
        %   - 좌우외곽경계는 날려버림.
        %   - 영서외곽경계는 유출구를 제외하고는 inf로 설정되어 있음.
        %     따라서 이들을 영서외곽경계에서 가장 낮은 유출구의 고도로 설정함.
        %   - 이후 watershed 함수를 이용하여 분수계를 파악함
        sOldElev = elev(Y_TOP_BND:Y_BOTTOM_BND,X_INI:X_MAX);
        outletX = find(elev(Y_TOP_BND,:) ~= inf);
        outletElev = elev(Y_TOP_BND,outletX);
        sOldElev(Y_TOP_BND,:) = outletElev;
        
        
        % (B) 영동과 영서로 향하는 2개의 유역분지를 만들기 위한 마스크 만들기
        %     * 마스크는 이진 자료형으로 나가는 면을 true로 설정해야 함.
        boundMask = false(mRows,X);
        boundMask(Y_TOP_BND,:) = true;
        boundMask(Y_BOTTOM_BND,:) = true;

        % (C) regional minimum 제거를 위한 고도 보정
        modifiedSOldElev = imimposemin(sOldElev,boundMask);
        
        % (D) 영서와 영동 및 분수계 색인 정의
        L(Y_TOP_BND:Y_BOTTOM_BND,X_INI:X_MAX) = watershed(modifiedSOldElev);
        EAST_DRAINAGE = L(Y_BOTTOM_BND,X_INI);
        WEST_DRAINAGE = L(Y_TOP_BND,X_INI);
        WATERSHED_DIVIDE = 0;

        % (E) 유역 label을 시각화
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % a. 고도 투영
        figure(Hf_02);
        hold on

        % b. 분수계를 더욱 돋보이게 함
        b = bwboundaries(L == WATERSHED_DIVIDE,4);
        b1 = b{1};
        x = b1(:,2);
        y = b1(:,1);
        plot(x,y,'r','LineWidth',2)     
        
        end
        
        %------------------------------------------------------------------
        % Q. 횡단곡선상 속성
        
        % 퇴적물 운반능력 구하기
   
        % 만제유량시 하폭 [m]
        bankfullWidth = khw * bankfullDischarge .^ mhw;        
        
        fluvialTransportCapacity ...   % 임시 퇴적물 운반 능력[m^3/subDT]
            = ( bankfullWidth ...
            .* ( kfa .* ( bankfullDischarge ./ bankfullWidth ) .^ mfa ...
            .* integratedSlope .^ nfa ) );
        
        % 영동 유역 상류
        upperHillslope ...      % 사면 색인
            = transportMode(upperCrossProfileZone,:) == SOIL_MANTLED_HILLSLOPE ...
            | transportMode(upperCrossProfileZone,:) == BEDROCK_EXPOSED_HILLSLOPE;
        upperChannel ...        % 하천 색인
            = transportMode(upperCrossProfileZone,:) == ALLUVIAL_CHANNEL ...
            | transportMode(upperCrossProfileZone,:) == BEDROCK_CHANNEL; 
        

        % 사면 평균 풍화층 두께
        upperHillslopeSed = sedimentThick(upperCrossProfileZone,:);        
        extEastUpperHillRegolithThick(ithGraph,1) ...
            = mean(upperHillslopeSed(upperHillslope));
        
        % 하천 평균 퇴적층 두께
        upperChannelSed = sedimentThick(upperCrossProfileZone,:);       
        extEastUpperChannelSedThick(ithGraph,1) ...
            = mean(upperChannelSed(upperChannel));
        
        % 사면작용에 의한 퇴적층 두께 변화율
        upperHillDSedThick = dSedThickByHillslopePerDT(upperCrossProfileZone,:);
        extEastUpperHillDSedThick(ithGraph,1) ...
            = mean(upperHillDSedThick(upperHillslope));
        
        % 기반암 하상 침식율
        upperChannelDBedrockElev = dBedrockElevByFluvialPerDT(upperCrossProfileZone,:);
        extEastUpperChannelDBedrockElev(ithGraph,1) ...
            = mean(upperChannelDBedrockElev(upperChannel));
        
        % 하천에 의한 퇴적층 두께 변화율
        upperChannelDSedThick = dSedThickByFluvialPerDT(upperCrossProfileZone,:);
        extEastUpperChannelDSedThick(ithGraph,1) ...
            = mean(upperChannelDSedThick(upperChannel));
        
        % 융기율
        upperUpliftedHeight = upliftedHeightPerDT(upperCrossProfileZone,:);
        extEastUpperUpliftedHeight(ithGraph,1) = mean(upperUpliftedHeight(:));
        
        % 풍화율
        upperWeatheringRate = weatheringProduct(upperCrossProfileZone,:);
        extEastUpperChannelWeatheringRate(ithGraph,1) ...
            = mean(mean(upperWeatheringRate(upperChannel)));
        extEastUpperHillslopeWeatheringRate(ithGraph,1) ...
            = mean(mean(upperWeatheringRate(upperHillslope)));
        
        % 퇴적물 운반능력
        upperFluvialTransportCapacity = fluvialTransportCapacity(upperCrossProfileZone,:);
        extEastUpperFluvialTransportCapacity(ithGraph,1) ...
            = mean(upperFluvialTransportCapacity(upperChannel));
             
        
        % 영동 유역 중류
        middleHillslope ...     % 사면 색인
            = transportMode(middleCrossProfileZone,:) == SOIL_MANTLED_HILLSLOPE ...
            | transportMode(middleCrossProfileZone,:) == BEDROCK_EXPOSED_HILLSLOPE;          
        middleChannel ...       % 하천 색인
            = transportMode(middleCrossProfileZone,:) == ALLUVIAL_CHANNEL ...
            | transportMode(middleCrossProfileZone,:) == BEDROCK_CHANNEL;                  
        
        % 사면 평균 풍화층 두께
        middleHillslopeReg = sedimentThick(middleCrossProfileZone,:);
        extEastMiddleHillRegolithThick(ithGraph,1) ...
            = mean(middleHillslopeReg(middleHillslope));
        
        % 하천 평균 퇴적층 두께
        middleChannelSedThick = sedimentThick(middleCrossProfileZone,:);
        extEastMiddleChannelSedThick(ithGraph,1) ...
            = mean(middleChannelSedThick(middleChannel));
        
        % 사면작용에 의한 퇴적층 두께 변화율
        middleHillslopeDSedThick = dSedThickByHillslopePerDT(middleCrossProfileZone,:);
        extEastMiddleHillDSedThick(ithGraph,1) ...
            = mean(middleHillslopeDSedThick(middleHillslope));
        
        % 기반암 하상 침식율
        middleChannelDBedrockElev = dBedrockElevByFluvialPerDT(middleCrossProfileZone,:);
        extEastMiddleChannelDBedrockElev(ithGraph,1) ...
            = mean(middleChannelDBedrockElev(middleChannel));
        
        % 하천에 의한 퇴적층 두께 변화율
        middleChannelDSedThick = dSedThickByFluvialPerDT(middleCrossProfileZone,:);
        extEastMiddleChannelDSedThick(ithGraph,1) ...
            = mean(middleChannelDSedThick(middleChannel));
        
        % 융기율
        middleUpliftedHeight = upliftedHeightPerDT(middleCrossProfileZone,:);
        extEastMiddleUpliftedHeight(ithGraph,1) = mean(middleUpliftedHeight(:));   
        
        % 풍화율
        middleWeatheringRate = weatheringProduct(middleCrossProfileZone,:);
        extEastMiddleChannelWeatheringRate(ithGraph,1) ...
            = mean(mean(middleWeatheringRate(middleChannel)));
        extEastMiddleHillslopeWeatheringRate(ithGraph,1) ...
            = mean(mean(middleWeatheringRate(middleHillslope)));
        
        % 퇴적물 운반능력
        middleFluvialTransportCapacity = fluvialTransportCapacity(middleCrossProfileZone,:);
        extEastMiddleFluvialTransportCapacity(ithGraph,1) ...
            = mean(middleFluvialTransportCapacity(middleChannel));
        
        
        % 영동 유역 하류
        bottomHillslope ...             % 사면 색인
            = transportMode(lowerCrossProfileZone,:) == SOIL_MANTLED_HILLSLOPE ...
            | transportMode(lowerCrossProfileZone,:) == BEDROCK_EXPOSED_HILLSLOPE;    
        bottomChannel ...               % 하천 색인
            = transportMode(lowerCrossProfileZone,:) == ALLUVIAL_CHANNEL ...
            | transportMode(lowerCrossProfileZone,:) == BEDROCK_CHANNEL;  
        
        % 사면 평균 풍화층 두께
        bottomHillReg = sedimentThick(lowerCrossProfileZone,:);
        extEastBottomHillRegolithThick(ithGraph,1) ...
            = mean(bottomHillReg(bottomHillslope));
        
        % 하천 평균 퇴적층 두께
        bottomChannelSedThick = sedimentThick(lowerCrossProfileZone,:);
        extEastBottomChannelSedThick(ithGraph,1) ...
            = mean(bottomChannelSedThick(bottomChannel));      
        
        % 사면작용에 의한 퇴적층 두께 변화율
        lowerHillDSedThick = dSedThickByHillslopePerDT(lowerCrossProfileZone,:);
        extEastLowerHillDSedThick(ithGraph,1) ...
            = mean(lowerHillDSedThick(bottomHillslope));
        
        % 기반암 하상 침식율
        lowerChannelDBedrockElev = dBedrockElevByFluvialPerDT(lowerCrossProfileZone,:);
        extEastLowerChannelDBedrockElev(ithGraph,1) ...
            = mean(lowerChannelDBedrockElev(bottomChannel));
        
        % 하천에 의한 퇴적층 두께 변화율
        lowerChannelDSedThick = dSedThickByFluvialPerDT(lowerCrossProfileZone,:);
        extEastLowerChannelDSedThick(ithGraph,1) ...
            = mean(lowerChannelDSedThick(bottomChannel));
        
        % 융기율
        lowerUpliftedHeight = upliftedHeightPerDT(lowerCrossProfileZone,:);
        extEastLowerUpliftedHeight(ithGraph,1) = mean(lowerUpliftedHeight(:));  
        
        % 풍화율
        lowerWeatheringRate = weatheringProduct(lowerCrossProfileZone,:);
        extEastLowerChannelWeatheringRate(ithGraph,1) ...
            = mean(mean(lowerWeatheringRate(bottomChannel)));
        extEastLowerHillslopeWeatheringRate(ithGraph,1) ...
            = mean(mean(lowerWeatheringRate(bottomHillslope)));
        
        % 퇴적물 운반능력
        lowerFluvialTransportCapacity = fluvialTransportCapacity(lowerCrossProfileZone,:);
        extEastLowerFluvialTransportCapacity(ithGraph,1) ...
            = mean(lowerFluvialTransportCapacity(bottomChannel));
        
        %------------------------------------------------------------------
%         % R. 하천종단곡선
%         if SHOW_GRAPH == SHOW_GRAPH_YES
%         
%         % (A) figure 준비
%         figure(Hf_17);
%         clf                % figure plot을 지움
%        
%         % (B) 하천인 셀을 파악
%         channelCell ...
%             = (transportMode ~= SOIL_MANTLED_HILLSLOPE) ...
%             & (transportMode ~= BEDROCK_EXPOSED_HILLSLOPE) ...
%             & (transportMode ~= OUTER_BOUNDARY);
% 
%         % (C) 영동으로 흐르는 하천의 종단곡선
%         
%         % a. 영동으로 흐르는 하천 셀
%         topToBottomChannel = find(channelCell & L == EAST_DRAINAGE);
%         
%         % b. 영동 유역에 하천 셀이 있는 경우만 종단곡선을 작성함
%         [chanCellsNo,tmp] = size(topToBottomChannel);
%         if chanCellsNo > 0
%             
%             % a) 영동 유역에 하천 셀이 존재하는 경우
%             
%             % (a) 가장 큰 하구의 좌표
%             
%             % 모델 영역 경계에서 유량이 제일 많은 하구 셀의 X 좌표
%             [tmp,pX] = max(bankfullDischarge(Y_MAX,:));
%             pY = Y_MAX;                     % 하구 셀의 Y 좌표
%             
%             % (b) 종단곡선 초기화
%             profile1 = zeros(Y*X,2);
%             distance1 = zeros(Y*X,1);
%             profilePath = false(mRows,nCols);
%             
%             % (c) 하구 셀에서부터 유량이 가장 많은 이웃 셀의 좌표를 기록함
%             i = 1;                          % 하구로부터의 종단곡선상 셀 색인
%             profile1(i,:) = [pY,pX];        % 하구 셀의 좌표를 처음에 기록
%             distance1(i) = 0;               % 하구로부터의 거리 [m]
%             isEnd = false;
%             
%             while(isEnd == false)
% 
%                 i = i + 1;                  % 종단곡선상 셀 색인 1 증가
%                 profilePath(pY,pX) = true;  % 지나온 경로를 표시함
%                 
%                 % 1. 이웃 셀중 유량이 가장 많은 셀의 좌표를 구함
%                 
%                 % 좌우 연결이 되었을 경우, offsetX 수정
%                 if IS_LEFT_RIGHT_CONNECTED == true
%                     
%                     if pX == X_INI
%                         
%                         nbrX = pX + X_INI_OffsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     elseif pX == X_MAX
%                         
%                         nbrX = pX + X_MAX_OffsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     else
%                         
%                         nbrX = pX + offsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     end
%                     
%                 end                         
%                 
%                 nbrY = pY + offsetY;        % 이웃 셀 Y 좌표 배열
% 
%                 nbrIdx = sub2ind([mRows,nCols],nbrY,nbrX);                
%                 
%                 nbrDischarge = bankfullDischarge(nbrIdx); % 이웃 셀 유량 배열
%                 nbrProfilePath = profilePath(nbrIdx); % 지나온 경로
%                 
%                 % 이웃 셀 좌표, 유량 및 지형단위 정보를 묶음
%                 nbrInfo = [nbrY,nbrX,nbrDischarge,nbrProfilePath];
%                 
%                 % 지나온 경로상에 있는 셀이 아니면서 유량이 제일 큰 순서로 정렬함
%                 sortedNbrInfo = sortrows(nbrInfo,[4,-3]);
%                 
%                 % 이웃 셀중 유량이 가장 많은 셀의 좌표               
%                 newPY = sortedNbrInfo(1,1);
%                 newPX = sortedNbrInfo(1,2);
%                 
%                 % 2. 유량이 가장 많은 셀이 하천이고, 영동 유역에 속한다면 이를
%                 %    종단곡선에 기록함
%                 if transportMode(newPY,newPX) ~= SOIL_MANTLED_HILLSLOPE ...
%                     && transportMode(newPY,newPX) ~= BEDROCK_EXPOSED_HILLSLOPE ...
%                     && L(newPY,newPX) == EAST_DRAINAGE
%                 
%                     % 이웃 셀과의 거리를 구함
%                     if abs(pY-newPY) == 1 && abs(pX-newPX) == 1
%                         distance1(i) = distance1(i-1) + dX * ROOT2;
%                     else
%                         distance1(i) = distance1(i-1) + dX;
%                     end
% 
%                     % 이웃 셀의 좌표를 종단곡선에 기록함
%                     pY = newPY;
%                     pX = newPX;
% 
%                     profile1(i,:) = [pY,pX];
%                 
%                 else
%                     
%                     isEnd = true;
%                     
%                 end
% 
%             end
% 
%             % (d) 종단곡선 중 필요없는 값 제거
%             [tmp,profileEnd] = min(profile1(:,2));  % Null값이 나오는 위치
%             profile1 = sub2ind([mRows,nCols] ...    % 선형색인으로 변환
%                 ,profile1(1:profileEnd-1,1),profile1(1:profileEnd-1,2));
%             distance1 = distance1(1:profileEnd-1,1);
%         
%             % (e) plot
%             subplot(2,1,1)
%             % 기반암 하상 고도
%             plot(distance1,bedrockElev(profile1),'Color','Red','LineWidth',1)
%             hold on
%             % 기반암 하상 + 평균 퇴적층 두께
%             plot(distance1,bedrockElev(profile1) + sedimentThick(profile1) ...
%                 ,'Color','Blue','LineWidth',1)
%             % xlim([0 distance1(end)])
%             ylim([0 bedrockElev(profile1(end)) + sedimentThick(profile1(end))]);
%             set(gca,'XDir','reverse')               % 영동쪽은 X축을 반대로!
%             
%         end
%         
%         tmpTitle = [int2str(simulatingTime) 'th East Drainage Longitudinal River Profile'];
%         title(tmpTitle)
%         
%         % (D) 영서로 흐르는 하천의 종단곡선
%         
%         % a. 영서로 흐르는 하천 셀
%         bottomToTopChannel = find(channelCell & L == WEST_DRAINAGE);
%         
%         % b. 영서 유역에 하천 셀이 있는 경우만 종단곡선을 작성함
%         [chanCellsNo,tmp] = size(bottomToTopChannel);
%         if chanCellsNo > 0
%             
%             % a) 영서 유역에 하천 셀이 존재하는 경우
%             
%             % (a) 가장 큰 하구의 좌표
%             
%             % 모델 영역 경계에서 유량이 제일 많은 하구 셀의 X 좌표
%             [tmp,pX] = max(bankfullDischarge(Y_INI,:));
%             pY = Y_INI;                     % 하구 셀의 Y 좌표
%             
%             % (b) 종단곡선 초기화
%             profile2 = zeros(Y*X,2);
%             distance2 = zeros(Y*X,1);
%             profilePath = false(mRows,nCols);
%             
%             % (c) 하구 셀에서부터 유량이 가장 많은 이웃 셀의 좌표를 기록함
%             i = 1;                          % 하구로부터의 종단곡선상 셀 색인
%             profile2(i,:) = [pY,pX];        % 하구 셀의 좌표를 처음에 기록
%             distance2(i) = 0;               % 하구로부터의 거리 [m]
%             isEnd = false;
%             
%             while(isEnd == false)
% 
%                 i = i + 1;                  % 종단곡선상 셀 색인 1 증가
%                 profilePath(pY,pX) = true;  % 지나온 경로 표시
%                 
%                 % 1. 이웃 셀중 유량이 가장 많은 셀의 좌표를 구함
%                 
%                 % 좌우 연결이 되었을 경우, offsetX 수정
%                 if IS_LEFT_RIGHT_CONNECTED == true
%                     
%                     if pX == X_INI
%                         
%                         nbrX = pX + X_INI_OffsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     elseif pX == X_MAX
%                         
%                         nbrX = pX + X_MAX_OffsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     else
%                         
%                         nbrX = pX + offsetX;        % 이웃 셀 X 좌표 배열
%                         
%                     end
%                     
%                 end                        
%                 
%                 nbrY = pY + offsetY;        % 이웃 셀 Y 좌표 배열
% 
%                 nbrIdx = sub2ind([mRows,nCols],nbrY,nbrX);                
%                 
%                 nbrDischarge = bankfullDischarge(nbrIdx); % 이웃 셀 유량 배열
%                 nbrProfilePath = profilePath(nbrIdx); % 이웃 셀 지나온 경로 정보
%                 
%                 % 이웃 셀 좌표, 유량 및 지형단위 정보를 묶음
%                 nbrInfo = [nbrY,nbrX,nbrDischarge,nbrProfilePath];
%                 
%                 % 지나온 경로상에 있는 셀이 아니면서 유량이 제일 큰 순서로 정렬함
%                 sortedNbrInfo = sortrows(nbrInfo,[4 -3]);
%                 
%                 % 이웃 셀중 유량이 가장 많은 셀의 좌표               
%                 newPY = sortedNbrInfo(1,1);
%                 newPX = sortedNbrInfo(1,2);
%                 
%                 % 2. 유량이 가장 많은 셀이 하천이고, 영서 유역에 속한다면 이를
%                 %    종단곡선에 기록함
%                 if transportMode(newPY,newPX) ~= SOIL_MANTLED_HILLSLOPE ...
%                     && transportMode(newPY,newPX) ~= BEDROCK_EXPOSED_HILLSLOPE ...
%                     && L(newPY,newPX) == WEST_DRAINAGE
%                 
%                     % 이웃 셀과의 거리를 구함
%                     if abs(pY-newPY) == 1 && abs(pX-newPX) == 1
%                         distance2(i) = distance2(i-1) + dX * ROOT2;
%                     else
%                         distance2(i) = distance2(i-1) + dX;
%                     end
% 
%                     % 이웃 셀의 좌표를 종단곡선에 기록함
%                     pY = newPY;
%                     pX = newPX;
% 
%                     profile2(i,:) = [pY,pX];
%                 
%                 else
%                     
%                     isEnd = true;
%                     
%                 end
% 
%             end
% 
%             % (d) 종단곡선 중 필요없는 값 제거
%             [tmp,profileEnd] = min(profile2(:,2));  % Null값이 나오는 위치
%             profile2 = sub2ind([mRows,nCols] ...    % 선형색인으로 변환
%                 ,profile2(1:profileEnd-1,1),profile2(1:profileEnd-1,2));
%             distance2 = distance2(1:profileEnd-1,1);
%         
%             % (e) plot
%             subplot(2,1,2)
%             % 기반암 하상 고도
%             plot(distance2,bedrockElev(profile2),'Color','Red','LineWidth',1)
%             hold on
%             % 기반암 하상 + 평균 퇴적층 두께
%             plot(distance2,bedrockElev(profile2) + sedimentThick(profile2) ...
%                 ,'Color','Blue','LineWidth',1)
%             % xlim([0 distance2(end)])
%             ylim([0 bedrockElev(profile2(end)) + sedimentThick(profile2(end))]);
%             
%         end   
%         
%         tmpTitle = [int2str(simulatingTime) 'th West Drainage Longitudinal River Profile'];
%         title(tmpTitle)
%         
%         end
        
        %------------------------------------------------------------------
        % S. 유역분지 특성 그래프
        
        % (A) 영동과 영서 지역 색인
        L(Y_TOP_BND,X_INI:X_MAX) = 0;
        L(Y_BOTTOM_BND,X_INI:X_MAX) = 0;       
        eastDrainage = L == EAST_DRAINAGE;
        eastDrainageCellsNo = sum(eastDrainage(:));
        westDrainage = L == WEST_DRAINAGE;
        westDrainageCellsNo = sum(westDrainage(:));
        
        % (B) 현재까지의 시간축
        endTimeX = firstGraphShowTime + (ithGraph-1) * dGraphShowTime * dT;
        timeX = firstGraphShowTime:dGraphShowTime*dT:endTimeX;
        
        % (C) 평균 고도와 평균 경사
        facetFlowSlope(isinf(facetFlowSlope)) = NaN;
        
        eastMeanElev(ithGraph) = mean(elev(eastDrainage));
        eastMeanSlope(ithGraph) = nanmean(facetFlowSlope(eastDrainage));
        westMeanElev(ithGraph) = mean(elev(westDrainage));
        westMeanSlope(ithGraph) = nanmean(facetFlowSlope(westDrainage));
        
        % * 그래프
        maxElev = max(max(eastMeanElev(1:ithGraph)) ...
            ,max(westMeanElev(1:ithGraph)));
        maxSlope = max(max(eastMeanSlope(1:ithGraph)) ...
            ,max(westMeanSlope(1:ithGraph)));
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        figure(Hf_18);
        
        subplot(2,1,1)
        [AX,H1,H2] ...
            = plotyy(timeX,eastMeanElev(1:ithGraph) ...
            ,timeX,eastMeanSlope(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Elevation')
        set(get(AX(2),'Ylabel'),'String','Mean Slope')
        set(AX(1),'ylim',[0 maxElev],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxSlope],'xlim',[0 endTimeX])
        
        % xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')
        tmpTitle = [int2str(simulatingTime) 'th East Drainage Geomorphic Char.'];
        title(tmpTitle)
        
        subplot(2,1,2)
        [AX,H1,H2] ...
            = plotyy(timeX,westMeanElev(1:ithGraph) ...
            ,timeX,westMeanSlope(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Elevation')
        set(get(AX(2),'Ylabel'),'String','Mean Slope')
        set(AX(1),'ylim',[0 maxElev],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxSlope],'xlim',[0 endTimeX])
        xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')        
        tmpTitle = [int2str(simulatingTime) 'th West Drainage Geomorphic Char.'];
        title(tmpTitle)
        
        end
        
        % (D) 하계밀도
        drainageNetwork = bedrockChan | alluvialChan;
        eastDrainageDensity = sum(drainageNetwork(eastDrainage)) * dX ...
            / (eastDrainageCellsNo * dX * dX);
        westDrainageDensity = sum(drainageNetwork(westDrainage)) * dX ...
            / (westDrainageCellsNo * dX * dX);
        
        % (E) 운반환경 비율
        eastSoilMantledHillRatio ...
            = sum(soilMantledHill(eastDrainage)) / eastDrainageCellsNo;
        westSoilMantledHillRatio ...
            = sum(soilMantledHill(westDrainage)) / westDrainageCellsNo;
        
        eastBedrockExposedHillRatio ...
            = sum(bedrockExposedHill(eastDrainage)) / eastDrainageCellsNo;
        westBedrockExposedHillRatio ...
            = sum(bedrockExposedHill(:)) / westDrainageCellsNo;
        
        eastAlluvialChanRatio ...
            = sum(alluvialChan(eastDrainage)) / eastDrainageCellsNo;
        westAlluvialChanRatio ...
            = sum(alluvialChan(westDrainage)) / westDrainageCellsNo;
        
        eastBedrockChanRatio ...
            = sum(bedrockChan(eastDrainage)) / eastDrainageCellsNo;
        westBedrockChanRatio ...
            = sum(bedrockChan(westDrainage)) / westDrainageCellsNo;        
        
        % (D) 구성물질 특성
        eastMeanSedimentThick(ithGraph) ...
            = mean(sedimentThick(eastDrainage));
        eastMeanWeatheringProduct(ithGraph) ...
            = mean(weatheringProduct(eastDrainage));
        westMeanSedimentThick(ithGraph) ...
            = mean(sedimentThick(westDrainage));
        westMeanWeatheringProduct(ithGraph) ...
            = mean(weatheringProduct(westDrainage));        
        
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % * 그래프
        maxSedThick = max(max(eastMeanSedimentThick(1:ithGraph)) ...
            ,max(westMeanSedimentThick(1:ithGraph)));
        maxWeathering = max(max(eastMeanWeatheringProduct(1:ithGraph)) ...
            ,max(westMeanWeatheringProduct(1:ithGraph)));
        
        figure(Hf_19);
        
        subplot(2,1,1);
        [AX,H1,H2] ...
            = plotyy(timeX,eastMeanSedimentThick(1:ithGraph) ...
            ,timeX,eastMeanWeatheringProduct(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Sediment Thickness')
        set(get(AX(2),'Ylabel'),'String','Mean Weathering Product')
        % xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')
        set(AX(1),'ylim',[0 maxSedThick],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxWeathering],'xlim',[0 endTimeX])
        tmpTitle = [int2str(simulatingTime) 'th East Drainage Material Char'];
        title(tmpTitle)
        
        subplot(2,1,2);
        [AX,H1,H2] ...
            = plotyy(timeX,westMeanSedimentThick(1:ithGraph) ...
            ,timeX,westMeanWeatheringProduct(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Sediment Thickness')
        set(get(AX(2),'Ylabel'),'String','Mean Weathering Product')
        xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')
        set(AX(1),'ylim',[0 maxSedThick],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxWeathering],'xlim',[0 endTimeX])
        tmpTitle = [int2str(simulatingTime) 'th West Drainage Material Char'];
        title(tmpTitle)
        
        end
        
        %------------------------------------------------------------------
        % T. 지형형성과정 특성
        
        % (A) 유역 평균 침식율 [m^3/m^2 East Drainage]
        
        % a. 사면작용에 의한 평균 침식율
        eastMeanHillslopeErosionRate ...
            = sum(dSedThickByHillslopePerDT(Y_BOTTOM_BND,:)) / eastDrainageCellsNo;
        westMeanHillslopeErosionRate ...
            = sum(dSedThickByHillslopePerDT(Y_TOP_BND,:)) / westDrainageCellsNo;
        
        % b. 빠른 사면작용에 의한 평균 침식율
        eastMeanRapidMassErosionRate ...
            = sum(dSedThickByRapidMassPerDT(Y_BOTTOM_BND,:)) / eastDrainageCellsNo;
        westMeanRapidMassErosionRate ...
            = sum(dSedThickByRapidMassPerDT(Y_TOP_BND,:)) / westDrainageCellsNo;
        
        % c. 하천에 의한 평균 침식율
        eastFluvialOutputFluxAtBnd = dSedThickByFluvialPerDT(Y_BOTTOM_BND,:);
        westFluvialOutputFluxAtBnd = dSedThickByFluvialPerDT(Y_TOP_BND,:);
        
        % * 주의: eastFluvialOutputFluxAtBnd 자체가 셀 면적으로 나눈 값이므로
        %   유역 평균값을 구하기 위해서는 셀 개수로 나누면 됨
        eastMeanFluvialErosionRate ...
            = sum(eastFluvialOutputFluxAtBnd) / eastDrainageCellsNo;
        westMeanFluvialErosionRate ...
            = sum(westFluvialOutputFluxAtBnd) / westDrainageCellsNo;        
        
        % d. 유역 평균 침식율
        eastMeanErosionRate(ithGraph) = eastMeanHillslopeErosionRate ...
            + eastMeanRapidMassErosionRate + eastMeanFluvialErosionRate;
        
        westMeanErosionRate(ithGraph) = westMeanHillslopeErosionRate ...
            + westMeanRapidMassErosionRate + westMeanFluvialErosionRate;        
        
        % (B) 유역 평균 융기율 [m/East Drainage]
        upliftedHeight(Y_INI:Y_MAX,X_INI:X_MAX) ...
            = (meanUpliftRateSpatialDistribution(Y_INI:Y_MAX,X_INI:X_MAX) ...
            ./ meanUpliftRateAtUpliftAxis) ...
            .* upliftRateTemporalDistribution(ithTimeStep);
        eastMeanUpliftedHeight(ithGraph) = mean(upliftedHeight(eastDrainage));
        westMeanUpliftedHeight(ithGraph) = mean(upliftedHeight(westDrainage));
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % (C) 그래프 축 설정
        maxErosionRate ...
            = max(max(eastMeanErosionRate(1:ithGraph)) ...
            ,max(max(westMeanErosionRate(1:ithGraph))));
        
        if maxErosionRate == 0
            maxErosionRate = 1 * 10^-10;
        end
        
        maxUpliftedHeight ...
            = max(max(eastMeanUpliftedHeight(1:ithGraph)) ...
            ,max(max(westMeanUpliftedHeight(1:ithGraph))));
        
        maxY = max(maxErosionRate,maxUpliftedHeight);
        
        % (D) 그래프
        figure(Hf_20);
        
        subplot(2,1,1);
        [AX,H1,H2] ...
            = plotyy(timeX,eastMeanErosionRate(1:ithGraph) ...
            ,timeX,eastMeanUpliftedHeight(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Erosion Rate')
        set(get(AX(2),'Ylabel'),'String','Mean Uplifted Height')
        % xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')
        set(AX(1),'ylim',[0 maxY],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxY],'xlim',[0 endTimeX])
        tmpTitle = [int2str(simulatingTime) 'th East Drainage Process Char'];
        title(tmpTitle)
        
        subplot(2,1,2);
        [AX,H1,H2] ...
            = plotyy(timeX,westMeanErosionRate(1:ithGraph) ...
            ,timeX,westMeanUpliftedHeight(1:ithGraph),'plot');
        set(get(AX(1),'Ylabel'),'String','Mean Erosion Rate')
        set(get(AX(2),'Ylabel'),'String','Mean Uplifted Height')
        set(AX(1),'ylim',[0 maxY],'xlim',[0 endTimeX])
        set(AX(2),'ylim',[0 maxY],'xlim',[0 endTimeX])       
        xlabel('Time')
        set(H1,'LineStyle','--')
        set(H2,'LineStyle',':')        
        tmpTitle = [int2str(simulatingTime) 'th West Drainage Process Char'];
        title(tmpTitle)
        
        end
        
        % (E) 사태발생셀 개수
        rapidMassOccured = (dSedThickByRapidMassPerDT < 0) ...
            | (dBedrockElevByRapidMassPerDT < 0);
        eastRapidMassFreq = sum(rapidMassOccured(eastDrainage));
        westRapidMassFreq = sum(rapidMassOccured(westDrainage));
        
        %------------------------------------------------------------------
        % U. 퇴적물[m] 수지
        % * 주의: 장차 하도 내 하상 퇴적물[m^3/ED] 수지로 범위를 넓혀갈 예정
        
        % a. 퇴적물 공급 측면
        eastDBedrockElevByFluvial ...             % 기반암 하상으로부터의 공급
            = mean(dBedrockElevByFluvialPerDT(eastDrainage));        
        eastMeanDBedrockElevByRapidMass ...     % 암석붕괴로 인한 공급
            = mean(dBedrockElevByRapidMassPerDT(eastDrainage));        
        eastMeanOldSedimentThick ...            % 초기 퇴적층 두께
            = mean(sedimentThick(eastDrainage));

        eastSedimentNewInput ...
            = eastMeanWeatheringProduct(ithGraph) ...
            - eastDBedrockElevByFluvial ...
            - eastMeanDBedrockElevByRapidMass;
        
        eastSedimentInput ...
            = eastSedimentNewInput + eastMeanOldSedimentThick;
        
        westDBedrockElevByFluvial ...             % 기반암 하상으로부터의 공급
            = mean(dBedrockElevByFluvialPerDT(westDrainage));        
        westMeanDBedrockElevByRapidMass ...     % 암석붕괴로 인한 공급
            = mean(dBedrockElevByRapidMassPerDT(westDrainage));        
        westMeanOldSedimentThick ...            % 초기 퇴적층 두께
            = mean(sedimentThick(westDrainage));

        westSedimentNewInput ...
            = westMeanWeatheringProduct(ithGraph) ...
            - westDBedrockElevByFluvial ...
            - westMeanDBedrockElevByRapidMass;
        
        westSedimentInput ...
            = westSedimentNewInput + westMeanOldSedimentThick;
        
        % b. 퇴적물 제거 측면
        eastMeanNextSedimentThick ...   % 잔존 퇴적층 두께
            = mean(sedimentThick(eastDrainage));       
        
        eastRemovedSedimentOutput ...
            = eastMeanFluvialErosionRate ...
            + eastMeanHillslopeErosionRate ...
            + eastMeanRapidMassErosionRate;
        
        eastSedimentOutput ...
            = eastRemovedSedimentOutput + eastMeanNextSedimentThick;
        
        westMeanNextSedimentThick ...   % 잔존 퇴적층 두께
            = mean(sedimentThick(westDrainage));       
        
        westRemovedSedimentOutput ...
            = westMeanFluvialErosionRate ...
            + westMeanHillslopeErosionRate ...
            + westMeanRapidMassErosionRate;
        
        westSedimentOutput ...
            = westRemovedSedimentOutput + westMeanNextSedimentThick;
        
        % c. 퇴적층 수지: 0 이 되어야 함 
        eastSedimentBudget = eastSedimentInput - eastSedimentOutput;        
        westSedimentBudget = westSedimentInput - westSedimentOutput;
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        % (C) 결과 출력
        figure(Hf_21)
        clf
        set(gcf,'Color','white');               % 바탕화면 하얀 색
        mTextBox = uicontrol('style','text');   % "text" uicontrol 만듦
        set(mTextBox,'Units','characters' ...   % 크기 단위 'characters'
            ,'FontSize',8 ...                  % 폰트 크기
            ,'Position',[4,0,60,21])           % 텍스트 상자 위치 및 크기
        set(mTextBox,'String' ...
            ,{sprintf('East Drainage Sediment Budget: %6.3f',eastSedimentBudget) ...
            ,sprintf('-------------------------------------------------------------------') ...
            ,sprintf('Old Sed[m]: %6.3f              / Current Sediment[m]: %6.3f' ...
            ,eastMeanOldSedimentThick,eastMeanNextSedimentThick) ...
            ,sprintf('Weathering[p]: %6.1f         /                                     ' ...
            ,eastMeanWeatheringProduct(ithGraph) / eastSedimentNewInput * 100) ...
            ,sprintf('Fluvial dBedElev[p]: %6.1f / Fluvial Erosio[p]n: %6.1f' ...
            ,- eastDBedrockElevByFluvial / eastSedimentNewInput * 100 ...
            ,eastMeanFluvialErosionRate / eastRemovedSedimentOutput * 100) ...
            ,sprintf('RapidMass dBedElev[p]: %6.1f / RapidMass Erosion[p]: %6.1f' ...
            ,- eastMeanDBedrockElevByRapidMass / eastSedimentNewInput * 100 ...
            ,eastMeanRapidMassErosionRate / eastRemovedSedimentOutput * 100) ...
            ,sprintf('                                              / SlowMass Erosion[p]: %6.1f' ...
            ,eastMeanHillslopeErosionRate / eastRemovedSedimentOutput * 100) ...
            ,sprintf('-------------------------------------------------------------------') ...
            ,sprintf('New Input[m]: %9.6f     / Total Output[m]: %9.6f' ...
            ,eastSedimentNewInput,eastRemovedSedimentOutput) ...
            ,sprintf('==================================================') ...
            ,sprintf('West Drainage Sediment Budget: %6.3f',westSedimentBudget) ...
            ,sprintf('-------------------------------------------------------------------') ...
            ,sprintf('Old Sed[m]: %6.3f              / Current Sediment[m]: %6.3f' ...
            ,westMeanOldSedimentThick,westMeanNextSedimentThick) ...
            ,sprintf('Weathering[p]: %6.1f         /                                     ' ...
            ,westMeanWeatheringProduct(ithGraph) / westSedimentNewInput * 100 ) ...
            ,sprintf('Fluvial dBedElev[p]: %6.1f / Fluvial Erosion[p]: %6.1f' ...
            ,- westDBedrockElevByFluvial / westSedimentNewInput * 100 ...
            ,westMeanFluvialErosionRate / westRemovedSedimentOutput * 100 ) ...
            ,sprintf('RapidMass dBedElev[p]: %6.1f / RapidMass Erosion[p]: %6.1f' ...
            ,-westMeanDBedrockElevByRapidMass / westSedimentNewInput * 100 ...
            ,westMeanRapidMassErosionRate / westRemovedSedimentOutput * 100) ...
            ,sprintf('                                              / SlowMass Erosion[p]: %6.f' ...
            ,westMeanHillslopeErosionRate / westRemovedSedimentOutput * 100) ...
            ,sprintf('-------------------------------------------------------------------') ...
            ,sprintf('New Input[m]: %9.6f     / Total Output[m]: %9.6f' ...
            ,westSedimentNewInput,westRemovedSedimentOutput)})
        % 텍스트 상자 색을 figure 색과 동일하게 설정함
        colorOfFigureWindow = get(Hf_21,'Color');
        set(mTextBox,'BackgroundColor',colorOfFigureWindow)
        
        end
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
            
        % (B) 하도 내 하상 퇴적물 수지
        figure(Hf_22);
        imagesc([0.5*dX dX distanceX-0.5*dX] ...
            ,[0.5*dX dX distanceY-0.5*dX] ...
            ,chanBedSedBudget(Y_INI:Y_MAX,X_INI:X_MAX));
        set(gca,'DataAspectRatio',[1 1 1])
        colorbar
        tmpTitle = [int2str(simulatingTime) 'th chanBedSed Budget'];
        title(tmpTitle)      
        
        end
        
        %------------------------------------------------------------------
        % V. i번째 (스트랄러식) 하천 차수
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        figure(Hf_23);

        % calculate flow accumulation and direction
        [A,M] = wflowacc(arrayXForGraph,arrayYForGraph,elev(Y_INI:Y_MAX,X_INI:X_MAX),'type','single');
        % let's simply assume that channels start where A is larger than 100;
        W = A>100;
        % and calculate the strahler stream order
        [S,nodes] = streamorder(M,W);
        % and visualize it
        subplot(1,2,1); 
        pcolor(arrayXForGraph,arrayYForGraph,+W); axis image; shading flat;
        set(gca,'YDir','reverse')
        colorbar
        title('Stream Network')
        subplot(1,2,2);
        pcolor(arrayXForGraph,arrayYForGraph,S); axis image; shading flat;
        set(gca,'YDir','reverse')
        colorbar
        hold on
        plot(arrayXForGraph(nodes),arrayYForGraph(nodes),'ks','MarkerFaceColor','g')
        title('Strahler Stream Order')
        
        end
       
        %------------------------------------------------------------------
        % W. i 번째 힙소메트리 곡선
        
        if SHOW_GRAPH == SHOW_GRAPH_YES
        
        figure(Hf_24);
        
        hypsometry(elev(Y_INI:Y_MAX,X_INI:X_MAX),20,[1 1],'ro-',[2 2],Hf_24,totalGraphShowTimesNo,ithGraph);
        
        end
        
        % 일정한 간격으로 주요 변수들을 기록함
        % 큰 간격으로 2차원 주요 변수들을 기록함
        if mod(ithGraph,EXTRACT_INTERVAL) == 0
            
            ithExtractTime = ithExtractTime + 1;
            
            extSedimentThick(:,:,ithExtractTime+1) = sedimentThick;
            extBedrockElev(:,:,ithExtractTime+1) = bedrockElev;
            extWeatheringProduct(:,:,ithExtractTime) = weatheringProduct;
            extDSedThickByHillslopePerDT(:,:,ithExtractTime) = dSedThickByHillslopePerDT;
            extDSedThickByRapidMassPerDT(:,:,ithExtractTime) = dSedThickByRapidMassPerDT;
            extDBedrockElevByRapidMassPerDT(:,:,ithExtractTime) = dBedrockElevByRapidMassPerDT;
            extDSedThickByFluvialPerDT(:,:,ithExtractTime) = dSedThickByFluvialPerDT;
            extDBedrockElevByFluvialPerDT(:,:,ithExtractTime) = dBedrockElevByFluvialPerDT;
            extChanBedSedBudget(:,:,ithExtractTime) = chanBedSedBudget;
            extUpslopeArea(:,:,ithExtractTime) = upslopeArea;
            extTransportMode(:,:,ithExtractTime) = transportMode;
            extFacetFlowSlope(:,:,ithExtractTime) = facetFlowSlope;
            
        end
        
        % 1차원
        extEastDrainageDensity(ithGraph,:) = eastDrainageDensity;
        extWestDrainageDensity(ithGraph,:) = westDrainageDensity;
        extEastSoilMantledHillRatio(ithGraph,:) = eastSoilMantledHillRatio;
        extWestSoilMantledHillRatio(ithGraph,:) = westSoilMantledHillRatio;
        extEastBedrockExposedHillRatio(ithGraph,:) = eastBedrockExposedHillRatio;
        extWestBedrockExposedHillRatio(ithGraph,:) = westBedrockExposedHillRatio;
        extEastAlluvialChanRatio(ithGraph,:) = eastAlluvialChanRatio;
        extWestAlluvialChanRatio(ithGraph,:) = westAlluvialChanRatio;
        extEastBedrockChanRatio(ithGraph,:) = eastBedrockChanRatio;
        extWestBedrockChanRatio(ithGraph,:) = westBedrockChanRatio;
        extEastRapidMassFreq(ithGraph,:) = eastRapidMassFreq;
        extWestRapidMassFreq(ithGraph,:) = westRapidMassFreq;
        
    end
    
end

% 기록한 주요 변수들을 구조체로 반환함
majorOutputs = struct('sedimentThick',extSedimentThick ...
    ,'bedrockElev',extBedrockElev ...
    ,'weatheringProduct',extWeatheringProduct ...
    ,'dSedThickByHillslopePerDT',extDSedThickByHillslopePerDT ...
    ,'dSedThickByRapidMassPerDT',extDSedThickByRapidMassPerDT ...
    ,'dBedrockElevByRapidMassPerDT',extDBedrockElevByRapidMassPerDT ...
    ,'dSedThickByFluvialPerDT',extDSedThickByFluvialPerDT ...
    ,'dBedrockElevByFluvialPerDT',extDBedrockElevByFluvialPerDT ...
    ,'chanBedSedBudget',extChanBedSedBudget ...
    ,'facetFlowSlope',extFacetFlowSlope ...
    ,'upslopeArea',extUpslopeArea ...
    ,'transportMode',extTransportMode ...
    ,'eastMeanElev',eastMeanElev ...
    ,'westMeanElev',westMeanElev ...
    ,'eastMeanSlope',eastMeanSlope ...
    ,'westMeanSlope',westMeanSlope ...
    ,'eastMeanErosionRate',eastMeanErosionRate ...
    ,'westMeanErosionRate',westMeanErosionRate ...
    ,'eastSedimentThick',eastMeanSedimentThick ...
    ,'westSedimentThick',westMeanSedimentThick ...
    ,'eastWeatheringProduct',eastMeanWeatheringProduct ...
    ,'westWeatheringProduct',westMeanWeatheringProduct ...
    ,'eastUpliftedHeight',eastMeanUpliftedHeight ...
    ,'westUpliftedHeight',westMeanUpliftedHeight ...
    ,'eastDrainageDensity',extEastDrainageDensity ...
    ,'westDrainageDensity',extWestDrainageDensity ...
    ,'eastSoilMantledHillRatio',extEastSoilMantledHillRatio ...
    ,'westSoilMantledHillRatio',extWestSoilMantledHillRatio ...
    ,'eastBedrockExposedHillRatio',extEastBedrockExposedHillRatio ...
    ,'westBedrockExposedHillRatio',extWestBedrockExposedHillRatio ...
    ,'eastAlluvialChanRatio',extEastAlluvialChanRatio ...
    ,'westAlluvialChanRatio',extWestAlluvialChanRatio ...
    ,'eastBedrockChanRatio',extEastBedrockChanRatio ...
    ,'westBedrockChanRatio',extWestBedrockChanRatio ...
    ,'eastRapidMassFreq',extEastRapidMassFreq ...
    ,'westRapidMassFreq',extWestRapidMassFreq ...
    ,'eastUpperHillRegolithThick',extEastUpperHillRegolithThick ...
    ,'eastMiddleHillRegolithThick',extEastMiddleHillRegolithThick ...
    ,'eastBottomHillRegolithThick',extEastBottomHillRegolithThick ...
    ,'eastUpperChannelSedThick',extEastUpperChannelSedThick ...
    ,'eastMiddleChannelSedThick',extEastMiddleChannelSedThick ...
    ,'eastBottomChannelSedThick',extEastBottomChannelSedThick ...  
    ,'eastUpperHillDSedThick',extEastUpperHillDSedThick ...  
    ,'eastMiddleHillDSedThick',extEastMiddleHillDSedThick ...  
    ,'eastLowerHillDSedThick',extEastLowerHillDSedThick ...  
    ,'eastUpperChannelDBedrockElev',extEastUpperChannelDBedrockElev ...  
    ,'eastMiddleChannelDBedrockElev',extEastMiddleChannelDBedrockElev ...  
    ,'eastLowerChannelDBedrockElev',extEastLowerChannelDBedrockElev ...  
    ,'eastUpperChannelDSedThick',extEastUpperChannelDSedThick ...  
    ,'eastMiddleChannelDSedThick',extEastMiddleChannelDSedThick ...  
    ,'eastLowerChannelDSedThick',extEastLowerChannelDSedThick ...
    ,'eastUpperUpliftedHeight',extEastUpperUpliftedHeight ...  
    ,'eastMiddleUpliftedHeight',extEastMiddleUpliftedHeight ...  
    ,'eastLowerUpliftedHeight',extEastLowerUpliftedHeight ... 
    ,'eastUpperChannelWeatheringRate',extEastUpperChannelWeatheringRate ...  
    ,'eastMiddleChannelWeatheringRate',extEastMiddleChannelWeatheringRate ...  
    ,'eastLowerChannelWeatheringRate',extEastLowerChannelWeatheringRate ...
    ,'eastUpperHillslopeWeatheringRate',extEastUpperHillslopeWeatheringRate ...  
    ,'eastMiddleHillslopeWeatheringRate',extEastMiddleHillslopeWeatheringRate ...  
    ,'eastLowerHillslopeWeatheringRate',extEastLowerHillslopeWeatheringRate ...
    ,'eastUpperFluvialTransportCapacity',extEastUpperFluvialTransportCapacity ...
    ,'eastMiddleFluvialTransportCapacity',extEastMiddleFluvialTransportCapacity ...
    ,'eastLowerFluvialTransportCapacity',extEastLowerFluvialTransportCapacity ...
    ,'Y',Y,'X',X,'Y_INI',Y_INI,'Y_MAX',Y_MAX,'X_INI',X_INI,'X_MAX',X_MAX ...
    ,'upperCrossProfileY',upperCrossProfileY ...
    ,'middleCrossProfileY',middleCrossProfileY ...
    ,'lowerCrossProfileY',lowerCrossProfileY ...
    ,'dX',dX,'dT',dT,'WRITE_INTERVAL',WRITE_INTERVAL ...
    ,'EXTRACT_INTERVAL',EXTRACT_INTERVAL,'GRAPH_INTERVAL',GRAPH_INTERVAL ...
    ,'totalExtractTimesNo',totalExtractTimesNo ...
    ,'totalGraphShowTimesNo',totalGraphShowTimesNo);        

% 2) 로그 파일을 출력한다.
logMessage = fileread(OUTPUT_FILE_LOG_PATH);
fprintf(logMessage);

%--------------------------------------------------------------------------
% 모든 출력 파일을 닫는다.
fclose(FID_WEATHER);
fclose(FID_SEDTHICK);
fclose(FID_BEDROCKELEV);
fclose(FID_dSEDTHICK_BYHILLSLOPE);
fclose(FID_CHANBEDSEDBUDGET);
fclose(FID_dSEDTHICK_BYFLUVIAL);
fclose(FID_dBEDROCKELEV_BYFLUVIAL);
fclose(FID_dSEDTHICK_BYRAPIDMASS);
fclose(FID_dBEDROCKELEV_BYRAPIDMASS);
fclose(FID_LOG);