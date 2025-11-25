object Form1: TForm1
  Left = 332
  Top = 279
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 238
  ClientWidth = 576
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 576
    Height = 238
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 16
    Width = 500
    Height = 21
    Caption = 'TILTOTT '#220'GYFELEK '#193'TM'#193'SOL'#193'SA A 2022 '#201'VR'#336'L'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 128
    Top = 80
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 288
    Top = 80
    Width = 147
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Panel1: TPanel
    Left = 72
    Top = 128
    Width = 433
    Height = 41
    BevelOuter = bvNone
    Caption = ' '
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 64
    Top = 176
    Width = 441
    Height = 41
    BevelOuter = bvNone
    Caption = ' '
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object SOURCETABLA: TIBTable
    Database = SOURCEDBASE
    Transaction = SOURCETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'ABIZ'
    Left = 200
    Top = 40
  end
  object SOURCEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL22.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SOURCETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 240
    Top = 40
  end
  object SOURCETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SOURCEDBASE
    AutoStopAction = saNone
    Left = 280
    Top = 40
  end
  object TARGETQUERY: TIBQuery
    Database = TARGETDBASE
    Transaction = targetTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 176
  end
  object TARGETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL23.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = targetTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 176
  end
  object targetTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TARGETDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 176
  end
end
