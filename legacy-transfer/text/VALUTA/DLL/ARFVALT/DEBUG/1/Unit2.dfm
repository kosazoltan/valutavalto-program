object ARFOLYAMVALTOZTATAS: TARFOLYAMVALTOZTATAS
  Left = 155
  Top = 83
  BorderIcons = []
  BorderStyle = bsNone
  Caption = #193'rfolyamkedvezm'#233'ny be'#225'llit'#225'sa ...'
  ClientHeight = 261
  ClientWidth = 411
  Color = clNavy
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 5
    Top = 5
    Width = 400
    Height = 250
    BevelInner = bvRaised
    Color = clSkyBlue
    TabOrder = 0
    object Label2: TLabel
      Left = 40
      Top = 54
      Width = 176
      Height = 24
      Caption = 'ALAP'#193'RFOLYAM:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object VALUTANEVPANEL: TPanel
      Left = 8
      Top = 8
      Width = 385
      Height = 25
      Caption = 'KANADAI DOLL'#193'R'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object ALAPARFOLYAMPANEL: TPanel
      Left = 224
      Top = 48
      Width = 105
      Height = 33
      Caption = '25,500'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel7: TPanel
      Left = 8
      Top = 104
      Width = 385
      Height = 33
      Caption = 'KEDVEZM'#201'NYES '#193'RFOLYAM'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object UJARFOLYAMEDIT: TEdit
      Left = 152
      Top = 152
      Width = 89
      Height = 36
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      Text = '26,500'
      OnEnter = UJARFOLYAMEDITEnter
      OnExit = UJARFOLYAMEDITExit
      OnKeyDown = UJARFOLYAMEDITKeyDown
    end
    object ARFMODIOKEGOMB: TBitBtn
      Left = 16
      Top = 208
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J '#193'RFOLYAM RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = ARFMODIOKEGOMBClick
    end
    object ARFMODICANCELGOMB: TBitBtn
      Left = 208
      Top = 208
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM AD KEDVEZM'#201'NYT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = ARFMODICANCELGOMBClick
    end
  end
end
