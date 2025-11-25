object ATADOLAPFORM: TATADOLAPFORM
  Left = 202
  Top = 127
  BorderStyle = bsNone
  Caption = 'ATADOLAPFORM'
  ClientHeight = 768
  ClientWidth = 810
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label32: TLabel
    Left = 162
    Top = 90
    Width = 502
    Height = 108
    Caption = #193'TAD'#211'LAP'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label31: TLabel
    Left = 144
    Top = 104
    Width = 502
    Height = 108
    Caption = #193'TAD'#211'LAP'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object MENUPANEL: TPanel
    Left = 230
    Top = 300
    Width = 345
    Height = 161
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 1
    object Shape2: TShape
      Left = 8
      Top = 0
      Width = 329
      Height = 153
      Shape = stRoundRect
    end
    object KITOLTOGOMB: TBitBtn
      Left = 16
      Top = 16
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = #193'TAD'#211'LAP KIT'#214'LT'#201'SE'
      TabOrder = 0
      OnClick = KITOLTOGOMBClick
    end
    object LETOLTOGOMB: TBitBtn
      Left = 16
      Top = 48
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = #193'TAD'#211'LAPOK LET'#214'LT'#201'SE'
      TabOrder = 1
      OnClick = LETOLTOGOMBClick
    end
    object KILEPESGOMB: TBitBtn
      Left = 16
      Top = 112
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 2
      OnClick = KILEPESGOMBClick
    end
  end
  object skiccpanel: TPanel
    Left = -999
    Top = 340
    Width = 273
    Height = 41
    Caption = 'NYOMTAT'#193'S ...'
    Color = clBackground
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    Visible = False
  end
  object ERTEKTARPANEL: TPanel
    Left = -1500
    Top = 16
    Width = 809
    Height = 768
    BevelOuter = bvNone
    TabOrder = 0
    Visible = False
    object Label16: TLabel
      Left = 248
      Top = 32
      Width = 3
      Height = 13
    end
    object Label17: TLabel
      Left = 256
      Top = 8
      Width = 319
      Height = 33
      Caption = #201'RT'#201'KT'#193'RI '#193'TAD'#211'LAP'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Bevel17: TBevel
      Left = 600
      Top = 672
      Width = 161
      Height = 73
    end
    object Bevel18: TBevel
      Left = 408
      Top = 320
      Width = 90
      Height = 161
    end
    object ETOKEGOMB: TBitBtn
      Left = 608
      Top = 680
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = #193'TAD'#211'LAP RENDBEN'
      TabOrder = 10
      OnClick = ETOKEGOMBClick
    end
    object ETMEGSEMGOMB: TBitBtn
      Left = 608
      Top = 710
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 11
      OnClick = ETMEGSEMGOMBClick
    end
    object ETATADPANEL: TPanel
      Tag = 1
      Left = 56
      Top = 56
      Width = 289
      Height = 97
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 12
      object Label8: TLabel
        Left = 64
        Top = 20
        Width = 69
        Height = 13
        Caption = 'sz'#225'm'#250' '#233'rt'#233'kt'#225'r'
      end
      object TLabel
        Left = 160
        Top = 16
        Width = 34
        Height = 13
        Caption = 'D'#225'tum:'
      end
      object Label9: TLabel
        Left = 20
        Top = 44
        Width = 81
        Height = 13
        Caption = #193'tad'#243' '#233'rt'#233'kt'#225'ros:'
      end
      object Label10: TLabel
        Left = 14
        Top = 64
        Width = 87
        Height = 13
        Caption = #193'tvev'#337' '#233'rt'#233'kt'#225'ros:'
      end
      object ETSZAMEDIT: TEdit
        Tag = 1
        Left = 24
        Top = 16
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 0
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object ETADVETDATUMEDIT: TEdit
        Tag = 2
        Left = 200
        Top = 16
        Width = 73
        Height = 21
        MaxLength = 10
        TabOrder = 1
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object ETATADOEDIT: TEdit
        Tag = 3
        Left = 104
        Top = 40
        Width = 169
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 20
        TabOrder = 2
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object ETATVEVOEDIT: TEdit
        Tag = 4
        Left = 104
        Top = 64
        Width = 169
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 20
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel19: TPanel
      Left = 136
      Top = 48
      Width = 129
      Height = 17
      Caption = #193'TAD'#193'S/'#193'TV'#201'TEL'
      Color = clWhite
      TabOrder = 0
    end
    object PENZKESZLETPANEL: TPanel
      Tag = 2
      Left = 360
      Top = 56
      Width = 409
      Height = 97
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 13
      object Panel9: TPanel
        Left = 8
        Top = 16
        Width = 136
        Height = 25
        Caption = 'EGYEZIK'
        Color = clWhite
        TabOrder = 0
      end
      object Panel10: TPanel
        Left = 144
        Top = 16
        Width = 127
        Height = 25
        Caption = 'NEM EGYEZIK'
        Color = clWhite
        TabOrder = 1
      end
      object Panel11: TPanel
        Left = 272
        Top = 16
        Width = 123
        Height = 25
        Caption = 'ELT'#201'R'#201'S'
        Color = clWhite
        TabOrder = 2
      end
      object EGYEZIKEDIT: TEdit
        Tag = 5
        Left = 8
        Top = 56
        Width = 129
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object NEMEGYEZIKEDIT: TEdit
        Tag = 6
        Left = 144
        Top = 56
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object ELTERESEDIT: TEdit
        Tag = 7
        Left = 272
        Top = 56
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel20: TPanel
      Left = 464
      Top = 48
      Width = 185
      Height = 17
      Caption = 'P'#201'NZK'#201'SZLET'
      Color = clWhite
      TabOrder = 1
    end
    object TARTOZASOKPANEL: TPanel
      Tag = 3
      Left = 56
      Top = 168
      Width = 193
      Height = 137
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 14
      object Panel14: TPanel
        Left = 8
        Top = 12
        Width = 45
        Height = 41
        Color = clWhite
        TabOrder = 0
        object Label11: TLabel
          Left = 8
          Top = 8
          Width = 29
          Height = 13
          Caption = #201'T'#193'R'
        end
        object Label12: TLabel
          Left = 8
          Top = 24
          Width = 30
          Height = 13
          Caption = 'SZ'#193'M'
        end
      end
      object Panel15: TPanel
        Left = 53
        Top = 12
        Width = 52
        Height = 41
        Color = clWhite
        TabOrder = 1
        object Label13: TLabel
          Left = 3
          Top = 8
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label14: TLabel
          Left = 14
          Top = 24
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel21: TPanel
        Left = 105
        Top = 12
        Width = 78
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 2
      end
      object TARTETSZAM1EDIT: TEdit
        Tag = 8
        Left = 8
        Top = 60
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTETSZAM2EDIT: TEdit
        Tag = 11
        Left = 8
        Top = 84
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTETSZAM3EDIT: TEdit
        Tag = 14
        Left = 8
        Top = 108
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTDNEM1EDIT: TEdit
        Tag = 9
        Left = 56
        Top = 60
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTDNEM2EDIT: TEdit
        Tag = 12
        Left = 56
        Top = 84
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTDNEM3EDIT: TEdit
        Tag = 15
        Left = 56
        Top = 108
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTSUM1EDIT: TEdit
        Tag = 10
        Left = 112
        Top = 60
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTSUM2EDIT: TEdit
        Tag = 13
        Left = 112
        Top = 84
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARTSUM3EDIT: TEdit
        Tag = 16
        Left = 112
        Top = 108
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel27: TPanel
      Left = 112
      Top = 160
      Width = 97
      Height = 17
      Caption = 'TARTOZ'#193'SOK'
      Color = clWhite
      TabOrder = 2
    end
    object KOVETELESPANEL: TPanel
      Tag = 4
      Left = 296
      Top = 168
      Width = 201
      Height = 137
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 15
      object Panel13: TPanel
        Left = 8
        Top = 16
        Width = 44
        Height = 41
        Color = clWhite
        TabOrder = 0
        object Label15: TLabel
          Left = 3
          Top = 8
          Width = 29
          Height = 13
          Caption = #201'T'#193'R'
        end
        object Label18: TLabel
          Left = 3
          Top = 24
          Width = 30
          Height = 13
          Caption = 'SZ'#193'M'
        end
      end
      object Panel22: TPanel
        Left = 52
        Top = 16
        Width = 53
        Height = 41
        Color = clWhite
        TabOrder = 1
        object Label19: TLabel
          Left = 3
          Top = 8
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label20: TLabel
          Left = 10
          Top = 24
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel23: TPanel
        Left = 106
        Top = 16
        Width = 80
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 2
      end
      object KOVERTSZAM1EDIT: TEdit
        Tag = 17
        Left = 12
        Top = 64
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVERTSZAM2EDIT: TEdit
        Tag = 20
        Left = 12
        Top = 88
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVERTSZAM3EDIT: TEdit
        Tag = 23
        Left = 12
        Top = 108
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVDNEM1EDIT: TEdit
        Tag = 18
        Left = 56
        Top = 64
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVDNEM2EDIT: TEdit
        Tag = 21
        Left = 56
        Top = 88
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVDNEM3EDIT: TEdit
        Tag = 24
        Left = 56
        Top = 108
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVSUM1EDIT: TEdit
        Tag = 19
        Left = 112
        Top = 64
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVSUM2EDIT: TEdit
        Tag = 22
        Left = 112
        Top = 88
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KOVSUM3EDIT: TEdit
        Tag = 25
        Left = 112
        Top = 108
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel31: TPanel
      Left = 352
      Top = 160
      Width = 97
      Height = 17
      Caption = 'K'#214'VETEL'#201'S'
      Color = clWhite
      TabOrder = 3
    end
    object WUAFAPANEL: TPanel
      Tag = 5
      Left = 536
      Top = 168
      Width = 233
      Height = 137
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 16
      object Panel25: TPanel
        Left = 8
        Top = 24
        Width = 87
        Height = 41
        Caption = 'D'#193'TUM'
        Color = clWhite
        TabOrder = 0
      end
      object Panel26: TPanel
        Left = 95
        Top = 24
        Width = 49
        Height = 41
        Color = clWhite
        TabOrder = 1
        object Label21: TLabel
          Left = 2
          Top = 8
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label22: TLabel
          Left = 8
          Top = 24
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel28: TPanel
        Left = 144
        Top = 24
        Width = 75
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 2
      end
      object WUDATUM1EDIT: TEdit
        Tag = 26
        Left = 8
        Top = 72
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object WUDATUM2EDIT: TEdit
        Tag = 29
        Left = 8
        Top = 96
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object WUDNEM1EDIT: TEdit
        Tag = 27
        Left = 96
        Top = 72
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object WUSUM1EDIT: TEdit
        Tag = 28
        Left = 144
        Top = 72
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object WUDNEM2EDIT: TEdit
        Tag = 30
        Left = 96
        Top = 96
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object WUSUM2EDIT: TEdit
        Tag = 31
        Left = 144
        Top = 96
        Width = 73
        Height = 21
        MaxLength = 9
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel35: TPanel
      Left = 584
      Top = 160
      Width = 137
      Height = 17
      Caption = 'WU/AFA RENDEL'#201'S'
      Color = clWhite
      TabOrder = 4
    end
    object BANKIBEPANEL: TPanel
      Tag = 6
      Left = 56
      Top = 320
      Width = 337
      Height = 161
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 17
      object Panel24: TPanel
        Left = 16
        Top = 13
        Width = 89
        Height = 41
        Caption = 'D'#193'TUM'
        Color = clWhite
        TabOrder = 0
      end
      object Panel29: TPanel
        Left = 106
        Top = 13
        Width = 49
        Height = 41
        Color = clWhite
        TabOrder = 1
        object Label23: TLabel
          Left = 3
          Top = 8
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label24: TLabel
          Left = 12
          Top = 24
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel30: TPanel
        Left = 155
        Top = 13
        Width = 87
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 2
      end
      object Panel32: TPanel
        Left = 242
        Top = 13
        Width = 87
        Height = 41
        Caption = #193'RFOLYAM'
        Color = clWhite
        TabOrder = 3
      end
      object BBEDATUM1EDIT: TEdit
        Tag = 32
        Left = 16
        Top = 60
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDATUM2EDIT: TEdit
        Tag = 36
        Left = 16
        Top = 84
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDATUM3EDIT: TEdit
        Tag = 40
        Left = 16
        Top = 108
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDATUM4EDIT: TEdit
        Tag = 44
        Left = 16
        Top = 132
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDNEM1EDIT: TEdit
        Tag = 33
        Left = 104
        Top = 60
        Width = 49
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBESUM1EDIT: TEdit
        Tag = 34
        Left = 160
        Top = 60
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEARF1EDIT: TEdit
        Tag = 35
        Left = 248
        Top = 60
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDNEM2EDIT: TEdit
        Tag = 37
        Left = 104
        Top = 84
        Width = 49
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDNEM3EDIT: TEdit
        Tag = 41
        Left = 104
        Top = 108
        Width = 49
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 12
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEDNEM4EDIT: TEdit
        Tag = 45
        Left = 104
        Top = 132
        Width = 49
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 13
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBESUM2EDIT: TEdit
        Tag = 38
        Left = 160
        Top = 84
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 14
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBESUM3EDIT: TEdit
        Tag = 42
        Left = 160
        Top = 108
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 15
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBESUM4EDIT: TEdit
        Tag = 46
        Left = 160
        Top = 132
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 16
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEARF2EDIT: TEdit
        Tag = 39
        Left = 248
        Top = 84
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 17
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEARF3EDIT: TEdit
        Tag = 43
        Left = 248
        Top = 108
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 18
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BBEARF4EDIT: TEdit
        Tag = 47
        Left = 248
        Top = 132
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 19
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel39: TPanel
      Left = 176
      Top = 312
      Width = 129
      Height = 17
      Caption = 'BANKI BESZ'#193'LL'#205'T'#193'S'
      Color = clWhite
      TabOrder = 5
    end
    object BANKIKIPANEL: TPanel
      Tag = 7
      Left = 536
      Top = 320
      Width = 233
      Height = 161
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 18
      object Panel33: TPanel
        Left = 8
        Top = 12
        Width = 87
        Height = 41
        Caption = 'D'#193'TUM'
        Color = clWhite
        TabOrder = 0
      end
      object Panel34: TPanel
        Left = 96
        Top = 12
        Width = 46
        Height = 41
        Color = clWhite
        TabOrder = 1
        object Label25: TLabel
          Left = 2
          Top = 3
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label26: TLabel
          Left = 8
          Top = 20
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel36: TPanel
        Left = 142
        Top = 12
        Width = 83
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 2
      end
      object BKIDATUM1EDIT: TEdit
        Tag = 48
        Left = 8
        Top = 56
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDNEM1EDIT: TEdit
        Tag = 49
        Left = 96
        Top = 56
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKISUM1EDIT: TEdit
        Tag = 50
        Left = 144
        Top = 56
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDATUM2EDIT: TEdit
        Tag = 51
        Left = 8
        Top = 80
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDATUM3EDIT: TEdit
        Tag = 54
        Left = 8
        Top = 104
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDATUM4EDIT: TEdit
        Tag = 57
        Left = 8
        Top = 128
        Width = 79
        Height = 21
        MaxLength = 10
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDNEM2EDIT: TEdit
        Tag = 52
        Left = 96
        Top = 80
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDNEM3EDIT: TEdit
        Tag = 55
        Left = 96
        Top = 104
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKIDNEM4EDIT: TEdit
        Tag = 58
        Left = 96
        Top = 128
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKISUM2EDIT: TEdit
        Tag = 53
        Left = 144
        Top = 80
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 12
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKISUM3EDIT: TEdit
        Tag = 56
        Left = 144
        Top = 104
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 13
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object BKISUM4EDIT: TEdit
        Tag = 59
        Left = 144
        Top = 128
        Width = 79
        Height = 21
        MaxLength = 9
        TabOrder = 14
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel43: TPanel
      Left = 584
      Top = 312
      Width = 129
      Height = 17
      Caption = 'BANKI KISZ'#193'LL'#205'T'#193'S'
      Color = clWhite
      TabOrder = 6
    end
    object PENZTARIRENDELESPANEL: TPanel
      Tag = 8
      Left = 56
      Top = 496
      Width = 369
      Height = 161
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 19
      object Panel38: TPanel
        Left = 16
        Top = 14
        Width = 81
        Height = 41
        Caption = 'D'#193'TUM'
        Color = clWhite
        TabOrder = 0
      end
      object RENDDATUM1EDIT: TEdit
        Tag = 60
        Left = 16
        Top = 62
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 1
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDATUM2EDIT: TEdit
        Tag = 65
        Left = 16
        Top = 86
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 2
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDATUM3EDIT: TEdit
        Tag = 70
        Left = 16
        Top = 110
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDATUM4EDIT: TEdit
        Tag = 75
        Left = 16
        Top = 134
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object Panel40: TPanel
        Left = 98
        Top = 14
        Width = 41
        Height = 41
        Color = clWhite
        TabOrder = 5
        object Label27: TLabel
          Left = 3
          Top = 8
          Width = 36
          Height = 13
          Caption = 'P'#201'NZT'
        end
        object Label28: TLabel
          Left = 4
          Top = 24
          Width = 30
          Height = 13
          Caption = 'SZ'#193'M'
        end
      end
      object Panel41: TPanel
        Left = 140
        Top = 14
        Width = 46
        Height = 41
        Color = clWhite
        TabOrder = 6
        object Label29: TLabel
          Left = 2
          Top = 8
          Width = 42
          Height = 13
          Caption = 'VALUTA'
        end
        object Label30: TLabel
          Left = 8
          Top = 24
          Width = 24
          Height = 13
          Caption = 'NEM'
        end
      end
      object Panel42: TPanel
        Left = 188
        Top = 14
        Width = 79
        Height = 41
        Caption = #214'SSZEG'
        Color = clWhite
        TabOrder = 7
      end
      object Panel44: TPanel
        Left = 272
        Top = 14
        Width = 81
        Height = 41
        Caption = #193'RFOLYAM'
        Color = clWhite
        TabOrder = 8
      end
      object RENDPT1EDIT: TEdit
        Tag = 61
        Left = 104
        Top = 62
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDPT2EDIT: TEdit
        Tag = 66
        Left = 104
        Top = 86
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDPT3EDIT: TEdit
        Tag = 71
        Left = 104
        Top = 110
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDPT4EDIT: TEdit
        Tag = 76
        Left = 104
        Top = 134
        Width = 33
        Height = 21
        MaxLength = 3
        TabOrder = 12
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDNEM1EDIT: TEdit
        Tag = 62
        Left = 142
        Top = 62
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 13
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDNEM2EDIT: TEdit
        Tag = 67
        Left = 144
        Top = 86
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 14
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDNEM3EDIT: TEdit
        Tag = 72
        Left = 144
        Top = 110
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 15
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDDNEM4EDIT: TEdit
        Tag = 77
        Left = 144
        Top = 134
        Width = 41
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 3
        TabOrder = 16
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDSUM1EDIT: TEdit
        Tag = 63
        Left = 186
        Top = 62
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 17
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDSUM2EDIT: TEdit
        Tag = 68
        Left = 186
        Top = 86
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 18
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDSUM3EDIT: TEdit
        Tag = 73
        Left = 186
        Top = 110
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 19
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDSUM4EDIT: TEdit
        Tag = 78
        Left = 186
        Top = 134
        Width = 81
        Height = 21
        MaxLength = 9
        TabOrder = 20
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDARF1EDIT: TEdit
        Tag = 64
        Left = 272
        Top = 62
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 21
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDARF2EDIT: TEdit
        Tag = 69
        Left = 272
        Top = 86
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 22
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDARF3EDIT: TEdit
        Tag = 74
        Left = 272
        Top = 110
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 23
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object RENDARF4EDIT: TEdit
        Tag = 79
        Left = 272
        Top = 134
        Width = 81
        Height = 21
        MaxLength = 8
        TabOrder = 24
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel50: TPanel
      Left = 144
      Top = 488
      Width = 185
      Height = 17
      Caption = 'P'#201'NZT'#193'RI RENDEL'#201'SEK'
      Color = clWhite
      TabOrder = 7
    end
    object ETKORLEVELPANEL: TPanel
      Tag = 9
      Left = 440
      Top = 496
      Width = 321
      Height = 161
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 20
      object Panel45: TPanel
        Left = 9
        Top = 13
        Width = 86
        Height = 41
        Caption = 'D'#193'TUM'
        Color = clWhite
        TabOrder = 0
      end
      object Panel46: TPanel
        Left = 96
        Top = 13
        Width = 94
        Height = 41
        Caption = 'IKTAT'#211'SZ'#193'M'
        Color = clWhite
        TabOrder = 1
      end
      object Panel47: TPanel
        Left = 190
        Top = 13
        Width = 121
        Height = 41
        Caption = 'T'#193'RGY'
        Color = clWhite
        TabOrder = 2
      end
      object KORDATUM1EDIT: TEdit
        Tag = 80
        Left = 8
        Top = 62
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 3
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KORDATUM2EDIT: TEdit
        Tag = 83
        Left = 8
        Top = 86
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 4
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KORDATUM3EDIT: TEdit
        Tag = 86
        Left = 8
        Top = 110
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 5
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object KORDATUM4EDIT: TEdit
        Tag = 89
        Left = 8
        Top = 134
        Width = 81
        Height = 21
        MaxLength = 10
        TabOrder = 6
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object IKTATO1EDIT: TEdit
        Tag = 81
        Left = 96
        Top = 62
        Width = 89
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 7
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object IKTATO2EDIT: TEdit
        Tag = 84
        Left = 96
        Top = 86
        Width = 89
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 8
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object IKTATO3EDIT: TEdit
        Tag = 87
        Left = 96
        Top = 110
        Width = 89
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 9
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object IKTATO4EDIT: TEdit
        Tag = 90
        Left = 96
        Top = 134
        Width = 89
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 10
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARGY1EDIT: TEdit
        Tag = 82
        Left = 192
        Top = 62
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 11
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARGY2EDIT: TEdit
        Tag = 85
        Left = 192
        Top = 86
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 12
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARGY3EDIT: TEdit
        Tag = 88
        Left = 192
        Top = 110
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 13
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object TARGY4EDIT: TEdit
        Tag = 91
        Left = 192
        Top = 134
        Width = 121
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 15
        TabOrder = 14
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel54: TPanel
      Left = 520
      Top = 488
      Width = 121
      Height = 17
      Caption = 'K'#214'RLEVELEK'
      Color = clWhite
      TabOrder = 8
    end
    object EGYEBINFOPANEL: TPanel
      Tag = 10
      Left = 56
      Top = 672
      Width = 521
      Height = 73
      BevelInner = bvLowered
      BevelOuter = bvLowered
      TabOrder = 21
      object ETINFO1EDIT: TEdit
        Tag = 92
        Left = 16
        Top = 16
        Width = 497
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 78
        TabOrder = 0
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
      object ETINFO2EDIT: TEdit
        Tag = 93
        Left = 16
        Top = 40
        Width = 497
        Height = 21
        CharCase = ecUpperCase
        MaxLength = 78
        TabOrder = 1
        OnEnter = EDITEnter
        OnExit = EDITExit
        OnKeyDown = ETSZAMEDITKeyDown
      end
    end
    object Panel55: TPanel
      Left = 224
      Top = 664
      Width = 185
      Height = 17
      Caption = 'EGY'#201'B FONTOS INFORM'#193'CI'#211'K'
      Color = clWhite
      TabOrder = 9
    end
    object takaro: TPanel
      Left = 584
      Top = 664
      Width = 185
      Height = 80
      BevelOuter = bvNone
      TabOrder = 22
      object BACKGOMB: TBitBtn
        Left = 8
        Top = 32
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A MEN'#368'RE'
        TabOrder = 0
        OnClick = BACKGOMBClick
      end
      object BitBtn1: TBitBtn
        Left = 8
        Top = 4
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = 'NYOMTAT'#193'S'
        TabOrder = 1
        OnClick = BitBtn1Click
      end
    end
  end
  object PrintDialog1: TPrintDialog
    Left = 32
    Top = 32
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 40
    OnTimer = INDITOTimer
    Left = 24
    Top = 64
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 600
    Top = 8
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\ertektar\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 632
    Top = 8
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 664
    Top = 8
  end
end
