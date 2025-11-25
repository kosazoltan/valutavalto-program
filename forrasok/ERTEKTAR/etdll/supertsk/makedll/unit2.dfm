object SUPERVISORFORM: TSUPERVISORFORM
  Left = 215
  Top = 114
  BorderStyle = bsNone
  Caption = 'SUPERVISORFORM'
  ClientHeight = 418
  ClientWidth = 610
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 609
    Height = 417
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 0
    object Shape1: TShape
      Left = 160
      Top = 8
      Width = 377
      Height = 393
      Brush.Color = 5592405
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 40
      Top = 56
      Width = 289
      Height = 31
      Caption = 'SUPERVISOR MEN'#220'JE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape2: TShape
      Left = 24
      Top = 104
      Width = 329
      Height = 153
      Brush.Color = 10066329
      Pen.Width = 2
      Shape = stRoundRect
    end
    object LOGFILEGOMB: TBitBtn
      Left = 40
      Top = 152
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'LOGFILE KIOLVAS'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = LOGFILEGOMBClick
    end
    object CIMLETSETUPGOMB: TBitBtn
      Left = 40
      Top = 120
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'C'#205'MLETEK BE'#193'LL'#205'T'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = CIMLETSETUPGOMBClick
    end
    object ESCAPEGOMB: TBitBtn
      Left = 40
      Top = 200
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A SUPERVISORI MEN'#220'B'#336'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = ESCAPEGOMBClick
    end
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 352
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 216
    Top = 352
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 256
    Top = 352
  end
end
