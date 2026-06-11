object Form2: TForm2
  Left = 187
  Top = 122
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 293
  ClientWidth = 373
  Color = clMoneyGreen
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label3: TLabel
    Left = 80
    Top = 96
    Width = 237
    Height = 19
    Caption = 'Z'#193'R'#193'SOK BE'#201'RKEZ'#201'S'#201'NEK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 136
    Top = 128
    Width = 122
    Height = 19
    Caption = 'ELLEN'#336'RZ'#201'SE'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
  end
  object MISSPANEL: TPanel
    Left = -777
    Top = 0
    Width = 369
    Height = 289
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 369
      Height = 289
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 24
      Top = 16
      Width = 303
      Height = 16
      Caption = #214'SSZESEN 168 P'#201'NZT'#193'R 2022.10.11 -I Z'#193'R'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 112
      Top = 40
      Width = 134
      Height = 16
      Caption = 'NEM '#201'RKEZETT BE !'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object MISSDBPANEL: TPanel
      Left = 98
      Top = 15
      Width = 25
      Height = 18
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object NAPPANEL: TPanel
      Left = 192
      Top = 15
      Width = 68
      Height = 18
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object MISSLIST: TListBox
      Left = 24
      Top = 96
      Width = 321
      Height = 145
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 2
    end
    object TOVABBGOMB: TBitBtn
      Left = 128
      Top = 256
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'TOV'#193'BB'
      TabOrder = 3
      OnClick = TOVABBGOMBClick
    end
  end
  object ATABLA: TIBTable
    Database = ADBASE
    Transaction = ATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 48
  end
  object AQUERY: TIBQuery
    Database = ADBASE
    Transaction = ATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 48
  end
  object ADBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 216
    Top = 48
  end
  object ATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ADBASE
    AutoStopAction = saNone
    Left = 264
    Top = 48
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 320
    Top = 48
  end
end
