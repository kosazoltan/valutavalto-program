object GETVIPFORM: TGETVIPFORM
  Left = 366
  Top = 346
  BorderStyle = bsNone
  Caption = 'GETVIPFORM'
  ClientHeight = 107
  ClientWidth = 593
  Color = 4539717
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
    Left = 0
    Top = 0
    Width = 561
    Height = 60
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 521
      Height = 41
      Shape = stRoundRect
    end
    object ALLGOMB: TBitBtn
      Left = 16
      Top = 16
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'EXCLUSIVE K'#214'RLEVELEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = ALLGOMBClick
    end
    object CHIEFGOMB: TBitBtn
      Left = 360
      Top = 16
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'VEZET'#336'I K'#214'RLEVELEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = CHIEFGOMBClick
    end
    object BitBtn1: TBitBtn
      Left = 184
      Top = 16
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'Z'#193'LOG K'#214'RLEVELEK'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
  end
  object BitBtn2: TBitBtn
    Left = 472
    Top = 72
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#233'gsem'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = BitBtn2Click
  end
end
