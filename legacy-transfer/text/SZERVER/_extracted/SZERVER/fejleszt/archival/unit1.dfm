object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 606
  ClientWidth = 862
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
    Width = 862
    Height = 606
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 6
  end
  object Label1: TLabel
    Left = 192
    Top = 40
    Width = 521
    Height = 43
    Caption = 'R'#233'gebbi adatt'#225'bl'#225'k archiv'#225'l'#225'sa ....'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 32
    Top = 40
    Width = 89
    Height = 33
    Pen.Width = 2
    Shape = stEllipse
  end
  object Label2: TLabel
    Left = 40
    Top = 48
    Width = 71
    Height = 17
    Caption = 'dekanySoft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object STARTGOMB: TBitBtn
    Left = 168
    Top = 536
    Width = 281
    Height = 25
    Cursor = crHandPoint
    Caption = 'ARCHIV'#193'L'#193'S INDUL'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object ENDGOMB: TButton
    Left = 472
    Top = 536
    Width = 281
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = ENDGOMBClick
  end
  object Memo1: TMemo
    Left = 304
    Top = 112
    Width = 449
    Height = 385
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 528
    Top = 40
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 560
    Top = 40
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 592
    Top = 40
  end
end
