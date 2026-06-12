object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 315
  ClientWidth = 435
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
  object KONTROLLPANEL: TPanel
    Left = 0
    Top = 0
    Width = 433
    Height = 313
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 433
      Height = 313
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 32
      Top = 24
      Width = 351
      Height = 18
      Caption = 'A K'#214'VETKEZ'#336' P'#201'NZK'#201'SZLETEK ELLEN'#214'RZ'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 40
      Top = 88
      Width = 182
      Height = 19
      Caption = 'A valutav'#225'lt'#225's p'#233'nzk'#233'szlete:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 240
      Top = 56
      Width = 145
      Height = 19
      Caption = 'MEGSZ'#193'MOLTAD ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 48
      Top = 120
      Width = 172
      Height = 19
      Caption = 'A kezel'#233'si k'#246'lts'#233'g k'#233'szlete:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 24
      Top = 152
      Width = 197
      Height = 19
      Caption = 'A Western Union p'#233'nzk'#233'szlete:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 24
      Top = 184
      Width = 198
      Height = 19
      Caption = 'AFA visszat'#233'rit'#233's p'#233'nzk'#233'szlete:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 72
      Top = 216
      Width = 150
      Height = 19
      Caption = 'Foglal'#243'k p'#233'nzk'#233'szletei:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object TOVABBGOMB: TBitBtn
      Left = 136
      Top = 256
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'TOV'#193'BB'
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = TOVABBGOMBClick
    end
    object VVIGEN: TBitBtn
      Tag = 1
      Left = 232
      Top = 88
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Enabled = False
      TabOrder = 1
      OnClick = VVIGENClick
    end
    object VVNEM: TBitBtn
      Tag = 1
      Left = 312
      Top = 88
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Enabled = False
      TabOrder = 2
      OnClick = VVNEMClick
    end
    object KKIGEN: TBitBtn
      Tag = 2
      Left = 232
      Top = 120
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Enabled = False
      TabOrder = 3
      OnClick = VVIGENClick
    end
    object KKNEM: TBitBtn
      Tag = 2
      Left = 312
      Top = 120
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Enabled = False
      TabOrder = 4
      OnClick = VVNEMClick
    end
    object WUIGEN: TBitBtn
      Tag = 3
      Left = 232
      Top = 152
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Enabled = False
      TabOrder = 5
      OnClick = VVIGENClick
    end
    object WUNEM: TBitBtn
      Tag = 3
      Left = 312
      Top = 152
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Enabled = False
      TabOrder = 6
      OnClick = VVNEMClick
    end
    object AFAIGEN: TBitBtn
      Tag = 4
      Left = 232
      Top = 184
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Enabled = False
      TabOrder = 7
      OnClick = VVIGENClick
    end
    object AFANEM: TBitBtn
      Tag = 4
      Left = 312
      Top = 184
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Enabled = False
      TabOrder = 8
      OnClick = VVNEMClick
    end
    object FOGLIGEN: TBitBtn
      Tag = 5
      Left = 232
      Top = 216
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Enabled = False
      TabOrder = 9
      OnClick = VVIGENClick
    end
    object FOGLNEM: TBitBtn
      Tag = 5
      Left = 312
      Top = 216
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Enabled = False
      TabOrder = 10
      OnClick = VVNEMClick
    end
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 48
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 48
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 48
  end
end
