object GETUZLETSZAM: TGETUZLETSZAM
  Left = 355
  Top = 214
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'LISTA V'#193'LASZT'#193'S'
  ClientHeight = 338
  ClientWidth = 513
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
  object FOMENUPANEL: TPanel
    Left = 2
    Top = 2
    Width = 511
    Height = 335
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clMoneyGreen
    TabOrder = 0
    object Shape5: TShape
      Left = 0
      Top = 0
      Width = 511
      Height = 335
      Align = alClient
      Brush.Color = 6781877
      Pen.Width = 5
    end
    object Shape3: TShape
      Left = 16
      Top = 208
      Width = 473
      Height = 41
      Brush.Color = clBtnFace
      Shape = stRoundRect
    end
    object Shape2: TShape
      Left = 16
      Top = 160
      Width = 473
      Height = 41
      Brush.Color = clBtnFace
      Shape = stRoundRect
    end
    object SHAPE4: TShape
      Left = 312
      Top = 264
      Width = 161
      Height = 41
      Brush.Color = clBtnFace
      Shape = stRoundRect
    end
    object Shape1: TShape
      Left = 16
      Top = 64
      Width = 473
      Height = 41
      Brush.Color = clBtnFace
      Shape = stRoundRect
    end
    object Label3: TLabel
      Left = 104
      Top = 24
      Width = 344
      Height = 34
      Caption = 'V'#193'LASSZON EGYS'#201'GET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape11: TShape
      Left = 16
      Top = 112
      Width = 473
      Height = 41
      Shape = stRoundRect
    end
    object CHANGEKFTGOMB: TBitBtn
      Tag = 1
      Left = 24
      Top = 69
      Width = 457
      Height = 33
      Cursor = crHandPoint
      Caption = 'EXCLUSIVE BEST CHANGE '#214'SSZES'#205'TETT ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = CHANGEKFTGOMBClick
      OnEnter = CHANGEKFTGOMBEnter
      OnExit = CHANGEKFTGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object ERTEKTARAKGOMB: TBitBtn
      Tag = 2
      Left = 24
      Top = 164
      Width = 457
      Height = 33
      Cursor = crHandPoint
      Caption = #201'RT'#201'KT'#193'RAK '#214'SSZES'#205'TETT ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ERTEKTARAKGOMBClick
      OnEnter = CHANGEKFTGOMBEnter
      OnExit = CHANGEKFTGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object PENZTARAKGOMB: TBitBtn
      Tag = 3
      Left = 24
      Top = 212
      Width = 457
      Height = 33
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'RAK FORGALMI ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = PENZTARAKGOMBClick
      OnEnter = CHANGEKFTGOMBEnter
      OnExit = CHANGEKFTGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object megsemgomb: TBitBtn
      Tag = 4
      Left = 320
      Top = 268
      Width = 145
      Height = 33
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = megsemgombClick
      OnEnter = CHANGEKFTGOMBEnter
      OnExit = CHANGEKFTGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object ZALOGGOMB: TBitBtn
      Left = 24
      Top = 116
      Width = 457
      Height = 33
      Cursor = crHandPoint
      Caption = 'EXPRESSZ '#201'KSZERH'#193'Z '#201'S MINIBANK KFT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = ZALOGGOMBClick
      OnEnter = CHANGEKFTGOMBEnter
      OnExit = CHANGEKFTGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
  end
  object ERTEKTARPANEL: TPanel
    Left = -1289
    Top = 20
    Width = 282
    Height = 310
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clMoneyGreen
    TabOrder = 1
    object Shape6: TShape
      Left = 0
      Top = 0
      Width = 282
      Height = 310
      Align = alClient
      Brush.Color = 8454143
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 56
      Top = 16
      Width = 188
      Height = 33
      Caption = #201'RT'#201'KT'#193'RAK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object ERTEKTARCANCELGOMB: TBitBtn
      Left = 144
      Top = 272
      Width = 123
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = megsemgombClick
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object ERTEKTARLIST: TListBox
      Left = 16
      Top = 56
      Width = 249
      Height = 201
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 8454143
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 20
      ParentFont = False
      TabOrder = 1
      OnDblClick = ErtekTartValasztott
      OnKeyDown = ERTEKTARLISTKeyDown
    end
    object VALASZTOGOMB: TBitBtn
      Left = 16
      Top = 272
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'V'#193'LASZT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ErtekTartValasztott
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
  end
  object PENZTARPANEL: TPanel
    Left = -1987
    Top = 20
    Width = 347
    Height = 317
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clMoneyGreen
    TabOrder = 2
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 347
      Height = 317
      Align = alClient
      Brush.Color = 16311512
      Pen.Color = clTeal
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 96
      Top = 24
      Width = 188
      Height = 36
      Caption = 'P'#201'NZT'#193'RAK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PENZTARCANCELGOMB: TBitBtn
      Left = 184
      Top = 264
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = megsemgombClick
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
    object PENZTARLIST: TListBox
      Left = 32
      Top = 72
      Width = 297
      Height = 182
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 20
      ParentFont = False
      TabOrder = 1
      OnDblClick = PenztartValasztott
      OnKeyDown = PENZTARLISTKeyDown
    end
    object BitBtn1: TBitBtn
      Left = 48
      Top = 264
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'V'#193'LASZT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = PenztartValasztott
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = CHANGEKFTGOMBMouseMove
    end
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 288
  end
  object PARADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PARATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 288
  end
  object PARATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 88
    Top = 288
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 288
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 184
    Top = 288
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 288
  end
end
