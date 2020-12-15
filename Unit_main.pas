unit Unit_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Math, System.UITypes;

const
  MAX_BUFFER_LENGTH = 100; // Tamanho do buffer para opera��o com ModBus RTU

type
  ARR_BYTE = array [1 .. MAX_BUFFER_LENGTH] of byte; // Tipo de buffer para opera��o com ModBus RTU

type
  TForm1 = class(TForm)
    Button_ConnectOn: TButton;
    Timer_Polling: TTimer;
    Memo_Data: TMemo;
    Button_ConnectOff: TButton;
    RadioGroup_TypeRead: TRadioGroup;
    procedure Button_ConnectOnClick(Sender: TObject);
    procedure Timer_PollingTimer(Sender: TObject);
    procedure Button_ConnectOffClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    function InitPort(var h: Thandle; cport: string; access: dword): boolean;
    procedure ClosePort(var h: Thandle);
    function decoderParamFromPocketMB(numParam: word; sizeParam: word): string;
    procedure InitParam(typeParam: word);
    procedure RadioGroup_TypeReadClick(Sender: TObject);
  private
  public
  end;

const
  COM_PORT = 'COM7'; // Porta COM de conex�o

  FDCB: dcb = (BaudRate: 9600; ByteSize: 8; Parity: NOPARITY; Stopbits: TWOSTOPBITS); // Configura��es de conex�o

  TOUT: CommTimeouts = (ReadIntervalTimeout: 15; ReadTotalTimeoutConstant: 70;
    WriteTotalTimeoutMultiplier: 15; WriteTotalTimeoutConstant: 60); // Timeouts de conex�o

  D_DEMO_COIL = 0; // DEMONSTRA��O DE BANDEIRAS
  D_DEMO_REGISTER_WORD = 1; // Demonstra��o de leitura de registros por palavra
  D_DEMO_REGISTER_SINGLE = 2; // DEMONSTRA��O DA LOG�STICA COM LUZES SUPERIORES

  C_COIL = 0; // TAMANHO DE REFER�NCIA DO TIPO DE BANDEIRA MODBUS RTU EM BLOCOS (TWO-BAY)
  C_WORD = 1; // TAMANHO da palavra tipo ModBus RTU em unidades (compartimento duplo)
  C_SINGLE = 2; // Tamanho do tipo de ModBus RTU em unidades simples (frente e verso)

  R_COIL = 1;  // Comandando as Bandeiras ModBus RTU
  R_REGISTER = 3; // Comandos dos registradores ModBus RTU

  NUMBER_FLAGS = 56; // N�mero de bandeiras para entrega

  INQUIRY_BUFFER_LENGTH = 8; // Tamanho do buffer para opera��o com ModBus RTU
  MAX_RESPONSE_BUFFER_LENGTH = 1000; // Tamanho m�ximo do buffer para resposta ModBus RTU

var
  Form1: TForm1;

  hh: Thandle = 0; // Porta COM para escrita

  READ_COMMAND: word; // C�digo de comando de dados
  SIZE_PARAMETER: word; // TAMANHO DOS PAR�METROS
  NUMBER_PARAMETERS: word; // N�mero de par�metros
  NUMBER_DATA: word; // Quantidade de dados
  LENGTH_DATA: word; // TAMANHO DOS DADOS
  RESPONSE_BUFFER_LENGTH: word; // Tamanho do buffer para resposta ModBus RTU

  RESPONSE_FROM_PORT: array [1 .. MAX_RESPONSE_BUFFER_LENGTH] of byte; // Compat�vel com ModBus RTU

  INQUIRY_PORT: array [1 .. INQUIRY_BUFFER_LENGTH] of byte = ( // Solicitar transmiss�o do dispositivo
    01, // N�mero de unidade
    00, // C�digo complementar
    00, // Endere�o inicial para conex�o (compra antiga)
    00, // Endere�o inicial para conex�o (beb�)
    00,  // N�mero de pontos de conex�o (bytes antigos)
    00, // N�mero de pontos / bandeiras por muito tempo (compra de beb�)
    00,  // CRC16 ModBus RTU (mais jovem)
    00   // CRC16 ModBus RTU (arquivo antigo)
  );

implementation

{$R *.dfm}

uses Unit_CRC16_ModBus, Unit_utils;

procedure TForm1.InitParam(typeParam: word);
// C�lculo de par�metros de requisi��es de ModBus RTU
begin
  if  typeParam = D_DEMO_COIL then begin
    READ_COMMAND := R_COIL; // Logging ModBus RTU
    SIZE_PARAMETER := C_COIL; // Dimens�o dos par�metros em unidades
  end;

  if NUMBER_FLAGS mod 8 = 0 then begin
    NUMBER_PARAMETERS := (NUMBER_FLAGS div 8); // N�mero de par�metros a serem contados com o vidro
  end else begin
    NUMBER_PARAMETERS := (NUMBER_FLAGS div 8) +1; // N�mero de par�metros a serem contados com o vidro
  end;

  if typeParam = D_DEMO_REGISTER_WORD then begin
     READ_COMMAND := R_REGISTER; // Lendo Registros ModBus RTU
     SIZE_PARAMETER := C_WORD; // Dimens�o dos par�metros em unidades
     NUMBER_PARAMETERS := 10; // N�mero de par�metros a serem contados
  end;

  if typeParam = D_DEMO_REGISTER_SINGLE then begin
    READ_COMMAND := R_REGISTER; // Lendo Registros ModBus RTU
    SIZE_PARAMETER := C_SINGLE; // Dimens�o dos par�metros em unidades
    NUMBER_PARAMETERS := 10; // N�mero de par�metros a serem contados
  end;

  if typeParam = C_COIL then begin
    NUMBER_DATA := NUMBER_FLAGS; // N�mero de sinalizadores contados
    LENGTH_DATA := (NUMBER_FLAGS div 8) +1; //TAMANHO DAS COMPRAS CALCULADAS
  end else begin
    NUMBER_DATA := NUMBER_PARAMETERS * SIZE_PARAMETER; // N�mero de pontos contados
    LENGTH_DATA := NUMBER_DATA * 2; // Tamanho das unidades contadas em bytes
  end;

  RESPONSE_BUFFER_LENGTH := 5 + LENGTH_DATA; // Tamanho do buffer para resposta ModBus RTU

  INQUIRY_PORT[2] := READ_COMMAND; // Comando de Dados

  INQUIRY_PORT[6] := NUMBER_DATA; // N�mero de dados lidos
end;

function TForm1.InitPort(var h: Thandle; cport: string; access: dword): boolean;
// Inicializa��o da conex�o com a porta COM
var port: string; err_code: integer;
begin
  port := '\\.\' + cport; InitPort := false;
  if h <> 0 then Closehandle(h);
  h := CreateFile(Pchar(port), access, 0, Nil, OPEN_EXISTING, 0, 0);
  SetCommState(h, FDCB);
  SetCommTimeouts(h, TOUT);
  if h = high(h) then begin
    Closehandle(h); err_code := GetLastError;
    case err_code of
      5: begin
          MessageDlg('O acesso � porta ' + cport + ' est� desativado.' + #13#10 +
            'Descritor de porta =' + InttoStr(h), mtError, [mbOK], 0);
        end;
      6: begin
          MessageDlg('A porta ' + cport +
            ' n�o est� dispon�vel ou bloqueada por outro programa.' + #13#10 +
            'Descritor de porta =' + InttoStr(h), mtError, [mbOK], 0);
        end;
    end;
  end else InitPort := true;
end;

procedure TForm1.RadioGroup_TypeReadClick(Sender: TObject);
// Criticaliza��o dos par�metros dos dados
begin
  Memo_Data.Clear;
  InitParam(RadioGroup_TypeRead.ItemIndex);
end;

procedure TForm1.ClosePort(var h: Thandle);
// Desativar da porta COM
begin
  if h <> 0 then begin
    PurgeComm(h, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);
    Closehandle(h); h := 0;
  end;
end;

procedure TForm1.Button_ConnectOnClick(Sender: TObject);
// Conecte �s portas COM
begin
  Memo_Data.Lines.Clear;
  InitParam(RadioGroup_TypeRead.ItemIndex);
  if InitPort(hh, COM_PORT, GENERIC_READ OR GENERIC_WRITE) then Timer_Polling.Enabled := true;
end;

procedure TForm1.Timer_PollingTimer(Sender: TObject);
// Leitura de dados da porta COM
var bytesReceived: cardinal; bytesTransmitted: cardinal; numParam: integer; data: dword;
begin
  PurgeComm(hh, PURGE_TXABORT or PURGE_TXCLEAR);

  EscapeCommFunction(hh, SETRTS);

  data := CRC16(@INQUIRY_PORT, 6);

  INQUIRY_PORT[7] := lo(data); // CRC16
  INQUIRY_PORT[8] := hi(data); // CRC16

  WriteFile(hh, INQUIRY_PORT, INQUIRY_BUFFER_LENGTH, bytesTransmitted, nil); sleep(20);

  EscapeCommFunction(hh, CLRRTS);
  ReadFile(hh, RESPONSE_FROM_PORT, RESPONSE_BUFFER_LENGTH, bytesReceived, nil);

  if (bytesReceived = RESPONSE_BUFFER_LENGTH) AND (RESPONSE_FROM_PORT[3] = LENGTH_DATA) then begin
    Memo_Data.Lines.Clear;
    Memo_Data.Lines.Add('Pacote com pedido: [' +
      ConvertArrByteToStr(INQUIRY_PORT, length(INQUIRY_PORT))+']');
    Memo_Data.Lines.Add('Pacote com resposta: [' +
      ConvertArrByteToStr(RESPONSE_FROM_PORT, RESPONSE_BUFFER_LENGTH)+']');
    Memo_Data.Lines.Add('');
    Memo_Data.Lines.Add('Valores de dados dedicados:');
    for numParam := 0 to NUMBER_PARAMETERS - 1 do begin
      Memo_Data.Lines.Add('data' + inttostr(numParam + 1) + '=' +
        decoderParamFromPocketMB(numParam, SIZE_PARAMETER));
    end;
  end else begin
    Memo_Data.Lines.Clear; Memo_Data.Lines.Add('Cole��o de dados ...');
  end;
  Application.ProcessMessages;
end;

procedure TForm1.Button_ConnectOffClick(Sender: TObject);
// Desativar das portas COM
begin
  Timer_Polling.Enabled := false;
  Memo_Data.Clear;
  ClosePort(hh); ClosePort(hh);
end;

function TForm1.decoderParamFromPocketMB(numParam: word; sizeParam: word): string;
// C�digo de par�metro do pacote de resposta ModBus RTU
var offset: integer; byte1, byte2, byte3, byte4: byte; data: dword; rdata: single;
begin
  result := '';
  if SIZE_PARAMETER > 0 then offset := numParam * SIZE_PARAMETER * 2 else offset := numParam;
  case sizeParam of
    C_COIL: begin
        byte1 := RESPONSE_FROM_PORT[4 + offset];
        result := InttoStr(byte1) + ' ($' + inttohex(byte1,2) + ')';
      end;
    C_WORD: begin
        byte1 := RESPONSE_FROM_PORT[5 + offset];
        byte2 := RESPONSE_FROM_PORT[4 + offset];
        data := byteToWord(byte1, byte2);
        result := InttoStr(data) + ' ($' + inttohex(data,2) + ')';
      end;
    C_SINGLE: begin
        byte1 := RESPONSE_FROM_PORT[7 + offset];
        byte2 := RESPONSE_FROM_PORT[6 + offset];
        byte3 := RESPONSE_FROM_PORT[5 + offset];
        byte4 := RESPONSE_FROM_PORT[4 + offset];
        rdata := byteToReal(byte1, byte2, byte3, byte4);
        if Math.IsNan(rdata) or Math.IsInfinite(rdata) then
           result :='nenhum valor' else
           result := formatfloat('######0.000', rdata);
      end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Button_ConnectOffClick(Sender);
end;

end.
