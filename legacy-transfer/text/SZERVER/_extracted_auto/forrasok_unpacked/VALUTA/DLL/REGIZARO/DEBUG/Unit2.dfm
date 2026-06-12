object REGIZARASFORM: TREGIZARASFORM
  Left = 291
  Top = 262
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'REGIZARASFORM'
  ClientHeight = 219
  ClientWidth = 618
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 617
    Height = 217
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clSilver
    TabOrder = 0
    object Shape1: TShape
      Left = 16
      Top = 16
      Width = 585
      Height = 185
      Brush.Color = clGray
    end
    object Label1: TLabel
      Left = 72
      Top = 24
      Width = 500
      Height = 26
      Caption = 'EGY R'#201'GEBBI Z'#193'R'#193'S-LISTA KINYOMTAT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object EVCOMBO: TComboBox
      Left = 24
      Top = 80
      Width = 97
      Height = 37
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 29
      ParentFont = False
      TabOrder = 0
      Text = '2008'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 128
      Top = 80
      Width = 209
      Height = 37
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 29
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = EVCOMBOChange
    end
    object NAPCOMBO: TComboBox
      Left = 344
      Top = 80
      Width = 65
      Height = 37
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 29
      ParentFont = False
      TabOrder = 2
      Text = '25'
      OnChange = NAPCOMBOChange
    end
    object NAPNEVEDIT: TEdit
      Left = 416
      Top = 80
      Width = 169
      Height = 37
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
      Text = 'CS'#220'T'#214'RT'#214'K'
    end
    object STARTGOMB: TBitBtn
      Left = 128
      Top = 152
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'NYOMTAT'#193'S INDULHAT'
      TabOrder = 4
      OnClick = STARTGOMBClick
    end
    object ESCAPEGOMB: TBitBtn
      Left = 312
      Top = 152
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM NYOMTATOK'
      TabOrder = 5
      OnClick = ESCAPEGOMBClick
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = valutatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 160
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = valutatranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 160
  end
  object valutatranz: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 560
    Top = 160
  end
end
