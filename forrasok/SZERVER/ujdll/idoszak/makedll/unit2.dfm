object IDOSZAKBEFORM: TIDOSZAKBEFORM
  Left = 188
  Top = 123
  AlphaBlend = True
  AlphaBlendValue = 190
  BorderStyle = bsNone
  Caption = 'IDOSZAKBEFORM'
  ClientHeight = 155
  ClientWidth = 625
  Color = clOlive
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
    Width = 625
    Height = 153
    Brush.Color = 6781877
    Pen.Color = clOlive
    Pen.Width = 4
  end
  object Label1: TLabel
    Left = 32
    Top = 16
    Width = 575
    Height = 37
    Caption = 'K'#201'REM A VIZSG'#193'LAND'#211' ID'#336'SZAKOT'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 400
    Top = 66
    Width = 43
    Height = 24
    Caption = '-T'#211'L'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 536
    Top = 66
    Width = 24
    Height = 24
    Caption = '-IG'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 72
    Top = 64
    Width = 73
    Height = 28
    Cursor = crHandPoint
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 0
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 152
    Top = 64
    Width = 195
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 1
    OnChange = EVCOMBOChange
  end
  object TOLCOMBO: TComboBox
    Left = 352
    Top = 64
    Width = 49
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 20
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 2
    OnChange = TOLCOMBOChange
  end
  object IGCOMBO: TComboBox
    Left = 480
    Top = 64
    Width = 49
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 20
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 3
    OnChange = IGCOMBOChange
  end
  object IDSZOKEGOMB: TBitBtn
    Left = 152
    Top = 112
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'ID'#336'SZAK RENDBEN'
    TabOrder = 4
    OnClick = IDSZOKEGOMBClick
  end
  object IDSZCANCELGOMB: TBitBtn
    Left = 336
    Top = 112
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM ADOM MEG'
    TabOrder = 5
    OnClick = IDSZCANCELGOMBClick
  end
  object AQUERY: TIBQuery
    Database = ADBASE
    Transaction = ATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 88
  end
  object ADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 88
  end
  object ATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ADBASE
    AutoStopAction = saNone
    Left = 40
    Top = 128
  end
end
