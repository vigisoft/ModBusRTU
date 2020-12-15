object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ModBusRTU, ver. 3.0 [TS]'
  ClientHeight = 347
  ClientWidth = 364
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 12
  object Button_ConnectOn: TButton
    Left = 18
    Top = 287
    Width = 331
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Iniciar pesquisa'
    TabOrder = 0
    OnClick = Button_ConnectOnClick
  end
  object Memo_Data: TMemo
    Left = 18
    Top = 6
    Width = 331
    Height = 235
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Button_ConnectOff: TButton
    Left = 18
    Top = 318
    Width = 331
    Height = 24
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Parar'
    TabOrder = 2
    OnClick = Button_ConnectOffClick
  end
  object RadioGroup_TypeRead: TRadioGroup
    Left = 24
    Top = 245
    Width = 325
    Height = 32
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Modo de leitura de dados'
    Columns = 3
    ItemIndex = 0
    Items.Strings = (
      'coil'
      'word'
      'single')
    TabOrder = 3
    OnClick = RadioGroup_TypeReadClick
  end
  object Timer_Polling: TTimer
    Enabled = False
    OnTimer = Timer_PollingTimer
    Left = 120
    Top = 72
  end
end
