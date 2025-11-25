object Form1: TForm1
  Left = 420
  Top = 153
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 221
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 497
    Height = 221
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 24
    Width = 427
    Height = 23
    Caption = 'EXCLUSIVE BEST CHANGE JUTAL'#201'K ELLEN'#214'RZ'#201'SE '#201'S JAV'#205'T'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Impact'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 120
    Top = 72
    Width = 34
    Height = 21
    Caption = #201'V:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 232
    Top = 72
    Width = 81
    Height = 21
    Caption = 'H'#211'NAP:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 160
    Top = 184
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object EVEDIT: TEdit
    Left = 160
    Top = 68
    Width = 57
    Height = 32
    Cursor = crHandPoint
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    Text = '2022'
    OnEnter = EVEDITEnter
    OnExit = EVEDITExit
  end
  object HOEDIT: TEdit
    Left = 320
    Top = 68
    Width = 33
    Height = 32
    Cursor = crHandPoint
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    Text = '12'
    OnEnter = EVEDITEnter
    OnExit = EVEDITExit
  end
  object HONAPOKEGOMB: TBitBtn
    Left = 160
    Top = 112
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'H'#211'NAP RENDBEN'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = HONAPOKEGOMBClick
  end
  object MESSPANEL: TPanel
    Left = 16
    Top = 144
    Width = 473
    Height = 33
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 56
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 64
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 56
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 64
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 56
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 408
    Top = 64
  end
  object PTABLA: TIBTable
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 440
    Top = 72
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 104
    Top = 56
  end
end
