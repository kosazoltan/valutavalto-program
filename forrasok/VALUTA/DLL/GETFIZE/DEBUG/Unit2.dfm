object GETFIZETOESZKOZ: TGETFIZETOESZKOZ
  Left = 202
  Top = 149
  BorderStyle = bsNone
  Caption = 'GETFIZETOESZKOZ'
  ClientHeight = 113
  ClientWidth = 681
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape3: TShape
    Left = 0
    Top = 0
    Width = 681
    Height = 113
    Align = alClient
    Brush.Color = clRed
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label4: TLabel
    Left = 152
    Top = 24
    Width = 406
    Height = 29
    Caption = 'FIZET'#336'ESZK'#214'Z MEGHAT'#193'ROZ'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object KPGOMB: TBitBtn
    Left = 24
    Top = 64
    Width = 209
    Height = 25
    Cursor = crHandPoint
    Caption = 'K'#201'SZP'#201'NZES FIZET'#201'S'
    TabOrder = 0
    OnClick = KPGOMBClick
  end
  object BKGOMB: TBitBtn
    Left = 240
    Top = 64
    Width = 209
    Height = 25
    Cursor = crHandPoint
    Caption = 'BANKK'#193'RTY'#193'S FIZET'#201'S'
    TabOrder = 1
    OnClick = BKGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 456
    Top = 64
    Width = 209
    Height = 25
    Cursor = crHandPoint
    Caption = #220'GYF'#201'L EL'#193'LL A V'#193'S'#193'RL'#193'ST'#211'L'
    TabOrder = 2
    OnClick = MEGSEMGOMBClick
  end
  object noprosbennpanel: TPanel
    Left = -888
    Top = 5
    Width = 671
    Height = 103
    BevelOuter = bvNone
    Color = clFuchsia
    TabOrder = 3
    Visible = False
    object Label1: TLabel
      Left = 64
      Top = 16
      Width = 551
      Height = 23
      Caption = 'A P'#201'NZT'#193'ROS NINCS BEL'#201'PTETVE AZ OTP TERMIN'#193'LBA !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 168
      Top = 40
      Width = 340
      Height = 25
      Caption = 'PR'#211'B'#193'LJAM BEL'#201'PTETNI ?'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object BELEPGOMB: TBitBtn
      Left = 152
      Top = 72
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEL'#201'PTET'#201'S'
      TabOrder = 0
      OnClick = BELEPGOMBClick
    end
    object NEMLEPBEGOMB: TBitBtn
      Left = 344
      Top = 72
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 1
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 88
    Top = 16
  end
end
