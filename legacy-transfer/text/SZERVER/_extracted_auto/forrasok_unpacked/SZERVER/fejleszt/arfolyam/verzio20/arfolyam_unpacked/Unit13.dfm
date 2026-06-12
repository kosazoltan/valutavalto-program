object ZOLDMENU: TZOLDMENU
  Left = 240
  Top = 164
  BorderStyle = bsNone
  Caption = 'ZOLDMENU'
  ClientHeight = 154
  ClientWidth = 314
  Color = clGreen
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
    Left = 4
    Top = 4
    Width = 305
    Height = 145
    Color = clYellow
    TabOrder = 0
    object copygomb: TBitBtn
      Tag = 1
      Left = 8
      Top = 16
      Width = 281
      Height = 25
      Cursor = crHandPoint
      Caption = 'JEL'#214'LT TER'#220'LET M'#193'SOL'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = copygombClick
      OnEnter = copygombEnter
      OnExit = copygombExit
      OnMouseMove = copygombMouseMove
    end
    object LEHUZOGOMB: TBitBtn
      Tag = 2
      Left = 8
      Top = 56
      Width = 281
      Height = 25
      Cursor = crHandPoint
      Caption = 'FELS'#214' SOR(OK) LEHUZ'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = copygombClick
      OnEnter = copygombEnter
      OnExit = copygombExit
      OnMouseMove = copygombMouseMove
    end
    object MEGSEMGOMB: TBitBtn
      Tag = 3
      Left = 8
      Top = 96
      Width = 281
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = copygombClick
      OnEnter = copygombEnter
      OnExit = copygombExit
      OnMouseMove = copygombMouseMove
    end
  end
end
