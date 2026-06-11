object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 768
  ClientWidth = 1024
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
    Width = 1024
    Height = 768
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 1024
      Height = 768
      Align = alClient
      Brush.Color = clSilver
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 160
      Top = 24
      Width = 739
      Height = 49
      Caption = 'A VALUTA PROGRAM LOG-JAINAK LIST'#193'Z'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -37
      Font.Name = 'Gill Sans Ultra Bold Condensed'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object NAPTARPANEL: TPanel
      Left = 304
      Top = 184
      Width = 377
      Height = 297
      BevelOuter = bvNone
      Color = clGray
      TabOrder = 0
      object Label2: TLabel
        Left = 24
        Top = 16
        Width = 324
        Height = 22
        Caption = 'V'#193'LASSZA KI  A KIV'#193'NT D'#193'TUMOT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object NAPTAR: TCalendar
        Left = 24
        Top = 120
        Width = 320
        Height = 120
        StartOfWeek = 0
        TabOrder = 0
        OnChange = NAPTARChange
        OnDblClick = VALASZTOGOMBClick
        OnKeyDown = NAPTARKeyDown
      end
      object ELOHOGOMB: TBitBtn
        Left = 24
        Top = 88
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = '<<< el'#246'z'#337' h'#243'nap'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = ELOHOGOMBClick
      end
      object KOVHOGOMB: TBitBtn
        Left = 192
        Top = 88
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'k'#246'vetkez'#337' h'#243'nap >>>'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = KOVHOGOMBClick
      end
      object VALASZTOGOMB: TBitBtn
        Left = 24
        Top = 248
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'Ezt a napot k'#233'rem'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = VALASZTOGOMBClick
      end
      object DESCAPEGOMB: TBitBtn
        Left = 192
        Top = 248
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'Vissza a men'#252're'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnClick = DESCAPEGOMBClick
      end
      object datumpanel: TPanel
        Left = 96
        Top = 48
        Width = 185
        Height = 33
        Caption = '2018.11.01'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -27
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
      end
    end
    object DISPPANEL: TPanel
      Left = -2200
      Top = 64
      Width = 945
      Height = 625
      BevelOuter = bvNone
      Color = clSilver
      TabOrder = 1
      Visible = False
      object ListBox1: TListBox
        Left = 24
        Top = 56
        Width = 897
        Height = 529
        BorderStyle = bsNone
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = []
        ItemHeight = 17
        ParentFont = False
        TabOrder = 0
      end
      object FODATUMPANEL: TPanel
        Left = 24
        Top = 8
        Width = 897
        Height = 41
        BevelOuter = bvNone
        Caption = '2018 SZEPTEMBER 20 CS'#220'T'#214'RT'#214'K'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object masiknapgomb: TBitBtn
        Left = 240
        Top = 592
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#193'SIK NAPOT AKAROK MEGN'#201'ZNI'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = masiknapgombClick
      end
      object visszagomb: TBitBtn
        Left = 480
        Top = 592
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A MEN'#220'RE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = DESCAPEGOMBClick
      end
    end
  end
end
