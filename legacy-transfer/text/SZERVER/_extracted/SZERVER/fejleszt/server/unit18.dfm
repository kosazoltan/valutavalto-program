object GETUZLETSZAM: TGETUZLETSZAM
  Left = 195
  Top = 114
  BorderStyle = bsNone
  Caption = 'LISTA V'#193'LASZT'#193'S'
  ClientHeight = 496
  ClientWidth = 753
  Color = clTeal
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
    Left = 114
    Top = 26
    Width = 505
    Height = 329
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clTeal
    TabOrder = 0
    object Shape5: TShape
      Left = 8
      Top = 8
      Width = 489
      Height = 313
      Brush.Color = 8421631
      Pen.Width = 2
      Shape = stRoundRect
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
      Left = 64
      Top = 16
      Width = 391
      Height = 40
      Caption = 'V'#193'LASSZON EGYS'#201'GET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object EXCELSHAPE: TShape
      Left = 32
      Top = 264
      Width = 161
      Height = 41
      Shape = stRoundRect
    end
    object Shape8: TShape
      Left = 16
      Top = 112
      Width = 113
      Height = 41
      Shape = stRoundRect
    end
    object Shape9: TShape
      Left = 136
      Top = 112
      Width = 113
      Height = 41
      Shape = stRoundRect
    end
    object Shape10: TShape
      Left = 256
      Top = 112
      Width = 113
      Height = 41
      Shape = stRoundRect
    end
    object Shape11: TShape
      Left = 376
      Top = 112
      Width = 113
      Height = 41
      Shape = stRoundRect
    end
    object BESTCHANGEGOMB: TBitBtn
      Tag = 1
      Left = 24
      Top = 69
      Width = 457
      Height = 33
      Cursor = crHandPoint
      Caption = 'EXCLUSIVE CHANGE '#214'SSZES'#205'TETT ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = BESTCHANGEGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
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
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = ERTEKTARAKGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
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
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = PENZTARAKGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
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
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = megsemgombClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object EXCELGOMB: TBitBtn
      Left = 38
      Top = 268
      Width = 147
      Height = 33
      Cursor = crHandPoint
      Caption = 'EXCEL T'#193'BLA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = EXCELGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object BESTGOMB: TBitBtn
      Left = 24
      Top = 116
      Width = 97
      Height = 33
      Cursor = crHandPoint
      Caption = 'BEST'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = BESTGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object PANNONGOMB: TBitBtn
      Left = 144
      Top = 116
      Width = 97
      Height = 33
      Cursor = crHandPoint
      Caption = 'PANNON'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = PANNONGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object EASTGOMB: TBitBtn
      Left = 264
      Top = 116
      Width = 97
      Height = 33
      Cursor = crHandPoint
      Caption = 'EAST'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = EASTGOMBClick
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object BitBtn2: TBitBtn
      Left = 384
      Top = 116
      Width = 97
      Height = 33
      Cursor = crHandPoint
      Caption = 'Z'#193'LOG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = BitBtn2Click
      OnEnter = BESTCHANGEGOMBEnter
      OnExit = BESTCHANGEGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
  end
  object ERTEKTARPANEL: TPanel
    Left = -120
    Top = 424
    Width = 303
    Height = 321
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clTeal
    TabOrder = 1
    object Shape6: TShape
      Left = 8
      Top = 8
      Width = 281
      Height = 305
      Brush.Color = 8454143
      Pen.Width = 2
      Shape = stRoundRect
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
      Left = 152
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
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object ERTEKTARLIST: TListBox
      Left = 24
      Top = 64
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
      OnDblClick = ERTEKTARLISTDblClick
      OnKeyDown = ERTEKTARLISTKeyDown
    end
    object VALASZTOGOMB: TBitBtn
      Left = 24
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
      OnClick = VALASZTOGOMBClick
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
  end
  object PENZTARPANEL: TPanel
    Left = 376
    Top = 440
    Width = 370
    Height = 433
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clTeal
    TabOrder = 2
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 345
      Height = 417
      Brush.Color = 16311512
      Pen.Width = 2
      Shape = stRoundRect
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
      Top = 376
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
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
    object PENZTARLIST: TListBox
      Left = 32
      Top = 72
      Width = 297
      Height = 289
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
      OnDblClick = PENZTARLISTDblClick
      OnKeyDown = PENZTARLISTKeyDown
    end
    object BitBtn1: TBitBtn
      Left = 48
      Top = 376
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
      OnClick = BitBtn1Click
      OnEnter = VALASZTOGOMBEnter
      OnExit = VALASZTOGOMBExit
      OnMouseMove = BESTCHANGEGOMBMouseMove
    end
  end
end
