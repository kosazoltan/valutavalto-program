object Form1: TForm1
  Left = 457
  Top = 338
  Width = 338
  Height = 172
  BorderIcons = [biSystemMenu]
  Caption = 'Havi tabl'#243'k k'#233'szit'#233'se ....'
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
    Width = 330
    Height = 138
    Align = alClient
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 40
    Top = 16
    Width = 263
    Height = 28
    Caption = 'HAVI TABL'#211' K'#201'SZ'#205'T'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object MUNKANAPEDIT: TEdit
    Left = 112
    Top = 48
    Width = 121
    Height = 30
    Cursor = crHandPoint
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnEnter = MUNKANAPEDITEnter
    OnExit = MUNKANAPEDITExit
  end
  object MEHETGOMB: TBitBtn
    Left = 56
    Top = 88
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'MEHET'
    TabOrder = 1
    OnClick = MEHETGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 176
    Top = 88
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM'
    TabOrder = 2
    OnClick = MEGSEMGOMBClick
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 48
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 48
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 48
  end
end
