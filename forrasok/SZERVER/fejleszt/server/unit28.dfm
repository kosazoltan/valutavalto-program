object ADATMENU: TADATMENU
  Left = 192
  Top = 118
  BorderStyle = bsNone
  Caption = 'ADATMENU'
  ClientHeight = 368
  ClientWidth = 679
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
  object Panel1: TPanel
    Left = -8
    Top = 0
    Width = 681
    Height = 361
    Color = 170
    TabOrder = 0
    object Shape1: TShape
      Left = 40
      Top = 32
      Width = 617
      Height = 49
      Shape = stRoundRect
    end
    object Shape2: TShape
      Left = 96
      Top = 96
      Width = 481
      Height = 241
      Shape = stRoundRect
    end
    object FOCIMPANEL: TPanel
      Left = 48
      Top = 40
      Width = 601
      Height = 33
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object FORGALOMGOMB: TBitBtn
      Tag = 1
      Left = 128
      Top = 104
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#214'SZAKI FORGALOM KIMUTAT'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object KESZLETGOMB: TBitBtn
      Tag = 2
      Left = 104
      Top = 136
      Width = 465
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#214'SZAKI K'#201'SZLETEK, CIMLETEK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object WUNIGOMB: TBitBtn
      Tag = 3
      Left = 104
      Top = 168
      Width = 465
      Height = 25
      Cursor = crHandPoint
      Caption = 'WESTERN UNION '#201'S '#193'FAVISSZAT'#201'RIT'#201'S ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object PTARKOZTGOMB: TBitBtn
      Tag = 4
      Left = 104
      Top = 200
      Width = 465
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'RAK K'#214'Z'#214'TTI P'#201'NZMOZG'#193'SOK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object BANKIFORGGOMB: TBitBtn
      Tag = 5
      Left = 104
      Top = 232
      Width = 465
      Height = 25
      Cursor = crHandPoint
      Caption = 'BANKI FORGALOM ADATAI'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object VISSZAGOMB: TBitBtn
      Tag = 8
      Left = 312
      Top = 328
      Width = 81
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'MEN'#220'RE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object TRBGOMB: TBitBtn
      Tag = 6
      Left = 104
      Top = 264
      Width = 465
      Height = 25
      Cursor = crHandPoint
      Caption = 'A TRB MOZG'#193'SOK LIST'#193'I'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
    object stornogomb: TBitBtn
      Tag = 7
      Left = 120
      Top = 296
      Width = 433
      Height = 25
      Cursor = crHandPoint
      Caption = 'STORNO BIZONYLATOK'
      TabOrder = 8
      OnClick = FORGALOMGOMBClick
      OnEnter = FORGALOMGOMBEnter
      OnExit = FORGALOMGOMBExit
      OnMouseMove = FORGALOMGOMBMouseMove
    end
  end
end
