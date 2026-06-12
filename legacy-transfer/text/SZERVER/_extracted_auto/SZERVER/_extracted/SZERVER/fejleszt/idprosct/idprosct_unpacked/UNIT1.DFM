object Form1: TForm1
  Left = 192
  Top = 114
  Width = 710
  Height = 236
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 192
    Top = 56
    Width = 85
    Height = 20
    Caption = 'kezd'#337' p'#233'nzt'#225'r'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 72
    Top = 56
    Width = 44
    Height = 20
    Caption = 'H'#243'nap:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 88
    Top = 8
    Width = 544
    Height = 31
    Caption = 'P'#201'NZT'#193'ROSN'#201'V '#201'S ID-K'#211'D ELLEN'#214'RZ'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Button1: TButton
    Left = 112
    Top = 96
    Width = 193
    Height = 25
    Caption = 'START'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = Button1Click
  end
  object NEVPANEL: TPanel
    Left = 296
    Top = 128
    Width = 265
    Height = 41
    Caption = 'KOV'#193'CS ELEM'#201'R'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object IDPANEL: TPanel
    Left = 568
    Top = 128
    Width = 97
    Height = 41
    Caption = '12543'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object PENZTARPANEL: TPanel
    Left = 80
    Top = 128
    Width = 81
    Height = 41
    Caption = '125'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object DATUMPANEL: TPanel
    Left = 168
    Top = 128
    Width = 121
    Height = 41
    Caption = '2013.01.22'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object kezdoedit: TEdit
    Left = 288
    Top = 48
    Width = 49
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MaxLength = 3
    ParentFont = False
    TabOrder = 5
    Text = '3'
    OnEnter = HIANYKODEDITEnter
    OnExit = HIANYKODEDITExit
  end
  object hoedit: TEdit
    Left = 128
    Top = 48
    Width = 49
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MaxLength = 2
    ParentFont = False
    TabOrder = 6
    OnEnter = HIANYKODEDITEnter
    OnExit = HIANYKODEDITExit
  end
  object Button2: TButton
    Left = 520
    Top = 56
    Width = 145
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 7
    OnClick = Button2Click
  end
  object PTQUERY: TIBQuery
    Database = PTDBASE
    Transaction = pttranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object PTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PCONTROL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = pttranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object pttranz: TIBTransaction
    Active = False
    DefaultDatabase = PTDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 40
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 40
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 72
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 40
    Top = 72
  end
end
