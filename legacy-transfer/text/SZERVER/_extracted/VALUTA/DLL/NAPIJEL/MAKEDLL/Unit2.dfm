object NAPIJELENTES: TNAPIJELENTES
  Left = 203
  Top = 131
  BorderIcons = []
  BorderStyle = bsSingle
  ClientHeight = 746
  ClientWidth = 1031
  Color = 10551295
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clNavy
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object KULDOPANEL: TPanel
    Left = 712
    Top = 552
    Width = 297
    Height = 105
    Color = 16311512
    TabOrder = 10
    object Panel3: TPanel
      Left = 8
      Top = 8
      Width = 121
      Height = 25
      Caption = 'KEZEL'#201'SID'#205'J'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object KEZDIJERTEKPANEL: TPanel
      Left = 136
      Top = 8
      Width = 153
      Height = 25
      Caption = '257 426 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object Panel11: TPanel
      Left = 8
      Top = 40
      Width = 121
      Height = 25
      Caption = 'E-KERESKEDELEM'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object EKERERTEKPANEL: TPanel
      Left = 136
      Top = 40
      Width = 153
      Height = 25
      Caption = '345 000 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object BEKULDOGOMB: TBitBtn
      Left = 8
      Top = 72
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Jelent'#233's bek'#252'ld'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = BEKULDOGOMBClick
    end
    object CANCELGOMB: TBitBtn
      Left = 152
      Top = 72
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Most nem k'#252'ld'#246'm be'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = CANCELGOMBClick
    end
  end
  object KESZLETPANEL: TPanel
    Left = 8
    Top = 136
    Width = 353
    Height = 601
    TabOrder = 0
    object Panel8: TPanel
      Left = 8
      Top = 8
      Width = 337
      Height = 25
      Caption = 'Pillanatnyi p'#233'nzt'#225'r'#225'll'#225's'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object PILLRACS: TDBGrid
      Left = 1
      Top = 41
      Width = 351
      Height = 599
      DataSource = PILLSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clNavy
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Color = clRed
          Expanded = False
          FieldName = 'VALUTANEM'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Alignment = taCenter
          Title.Caption = 'DNEM'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ZARO'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clMaroon
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Alignment = taCenter
          Title.Caption = 'K'#201'SZLET'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 91
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VETEL'
          Title.Alignment = taCenter
          Title.Caption = 'V'#201'TEL'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 80
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELADAS'
          Title.Alignment = taCenter
          Title.Caption = 'ELAD'#193'S'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 81
          Visible = True
        end>
    end
  end
  object CIMLETPANEL: TPanel
    Left = 368
    Top = 184
    Width = 337
    Height = 233
    TabOrder = 1
    object Panel92: TPanel
      Left = 8
      Top = 32
      Width = 73
      Height = 17
      Caption = '20 000'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object C1PANEL: TPanel
      Left = 88
      Top = 32
      Width = 73
      Height = 17
      Caption = '4 500'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object Panel94: TPanel
      Left = 8
      Top = 56
      Width = 73
      Height = 17
      Caption = '10 000'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel95: TPanel
      Left = 176
      Top = 56
      Width = 73
      Height = 17
      Caption = '100'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object C8PANEL: TPanel
      Left = 256
      Top = 56
      Width = 73
      Height = 17
      Caption = '112'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object C2PANEL: TPanel
      Left = 88
      Top = 56
      Width = 73
      Height = 17
      Caption = '1 200'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object Panel98: TPanel
      Left = 176
      Top = 80
      Width = 73
      Height = 17
      Caption = '50'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object Panel99: TPanel
      Left = 8
      Top = 80
      Width = 73
      Height = 17
      Caption = '5 000'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object Panel100: TPanel
      Left = 8
      Top = 104
      Width = 73
      Height = 17
      Caption = '2 000'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object Panel101: TPanel
      Left = 8
      Top = 128
      Width = 73
      Height = 17
      Caption = '1 000'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object Panel102: TPanel
      Left = 8
      Top = 152
      Width = 73
      Height = 17
      Caption = '500'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
    end
    object Panel103: TPanel
      Left = 176
      Top = 32
      Width = 73
      Height = 17
      Caption = '200'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
    object Panel104: TPanel
      Left = 176
      Top = 104
      Width = 73
      Height = 17
      Caption = '20'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 12
    end
    object Panel105: TPanel
      Left = 176
      Top = 128
      Width = 73
      Height = 17
      Caption = '10'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 13
    end
    object C3PANEL: TPanel
      Left = 88
      Top = 80
      Width = 73
      Height = 17
      Caption = '500'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 14
    end
    object C9PANEL: TPanel
      Left = 256
      Top = 80
      Width = 73
      Height = 17
      Caption = '4'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 15
    end
    object C10PANEL: TPanel
      Left = 256
      Top = 104
      Width = 73
      Height = 17
      Caption = '166'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 16
    end
    object C4PANEL: TPanel
      Left = 88
      Top = 104
      Width = 73
      Height = 17
      Caption = '4 100'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 17
    end
    object C5PANEL: TPanel
      Left = 88
      Top = 128
      Width = 73
      Height = 17
      Caption = '6 321'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 18
    end
    object C11PANEL: TPanel
      Left = 256
      Top = 128
      Width = 73
      Height = 17
      Caption = '40'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 19
    end
    object C6PANEL: TPanel
      Left = 88
      Top = 152
      Width = 73
      Height = 17
      Caption = '430'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 20
    end
    object Panel113: TPanel
      Left = 176
      Top = 152
      Width = 73
      Height = 17
      Caption = '5'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 21
    end
    object C12PANEL: TPanel
      Left = 256
      Top = 152
      Width = 73
      Height = 17
      Caption = '13'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 22
    end
    object C7PANEL: TPanel
      Left = 256
      Top = 32
      Width = 73
      Height = 17
      Caption = '2 303 '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 23
    end
    object Panel120: TPanel
      Left = 8
      Top = 5
      Width = 321
      Height = 25
      Caption = 'Forint k'#233'szlet'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 24
    end
    object Panel1: TPanel
      Left = 8
      Top = 176
      Width = 321
      Height = 25
      Caption = 'Eur'#243' '#233'rme k'#233'szlet'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 25
    end
    object Panel2: TPanel
      Left = 8
      Top = 208
      Width = 73
      Height = 17
      Caption = '2'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
    end
    object EE2PANEL: TPanel
      Left = 88
      Top = 208
      Width = 73
      Height = 17
      Caption = 'XXX'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 27
    end
    object Panel4: TPanel
      Left = 176
      Top = 208
      Width = 73
      Height = 17
      Caption = '1'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 28
    end
    object EE1PANEL: TPanel
      Left = 256
      Top = 208
      Width = 73
      Height = 17
      Caption = 'XXX'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 29
    end
  end
  object WUPANEL: TPanel
    Left = 368
    Top = 552
    Width = 337
    Height = 105
    TabOrder = 2
    object Panel116: TPanel
      Left = 8
      Top = 8
      Width = 321
      Height = 25
      Caption = 'WESTERN UNION Z'#193'R'#211' K'#201'SZLETEI'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel118: TPanel
      Left = 8
      Top = 40
      Width = 153
      Height = 25
      Caption = 'HUF'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object Panel119: TPanel
      Left = 176
      Top = 40
      Width = 153
      Height = 25
      Caption = 'USD'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object WUHUFPANEL: TPanel
      Left = 8
      Top = 72
      Width = 153
      Height = 25
      Caption = '123 500 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object WUUSDPANEL: TPanel
      Left = 176
      Top = 72
      Width = 153
      Height = 25
      Caption = '$ 300 450 000'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
  end
  object AFAPANEL: TPanel
    Left = 368
    Top = 664
    Width = 337
    Height = 73
    TabOrder = 3
    object Panel124: TPanel
      Left = 8
      Top = 8
      Width = 321
      Height = 25
      Caption = #193'F'#193' INNOVA K'#201'SZLET'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel125: TPanel
      Left = 8
      Top = 40
      Width = 153
      Height = 25
      Caption = 'HUF'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object INNOVAPANEL: TPanel
      Left = 176
      Top = 40
      Width = 153
      Height = 25
      Caption = '345 000 789 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
  end
  object EGYEDIPANEL: TPanel
    Left = 712
    Top = 8
    Width = 297
    Height = 409
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    object Panel128: TPanel
      Left = 8
      Top = 8
      Width = 281
      Height = 25
      Caption = 'EGYEDI '#193'RFOLYAMOK'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object XVAL1PANEL: TPanel
      Left = 8
      Top = 80
      Width = 41
      Height = 25
      Caption = 'USD'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object XSUM1PANEL: TPanel
      Left = 56
      Top = 80
      Width = 80
      Height = 25
      Caption = '765 550 000'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object XARF1PANEL: TPanel
      Left = 140
      Top = 80
      Width = 60
      Height = 25
      Caption = '298,45'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object XBIZ1PANEL: TPanel
      Left = 203
      Top = 80
      Width = 89
      Height = 25
      Caption = 'V123456789'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object Panel133: TPanel
      Left = 8
      Top = 40
      Width = 41
      Height = 25
      Caption = 'Val.'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object Panel134: TPanel
      Left = 56
      Top = 40
      Width = 73
      Height = 25
      Caption = #214'sszeg'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object Panel135: TPanel
      Left = 136
      Top = 40
      Width = 55
      Height = 25
      Caption = #193'RF'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object Panel136: TPanel
      Left = 198
      Top = 40
      Width = 94
      Height = 25
      Caption = 'Bizonylat'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object XBIZ2PANEL: TPanel
      Left = 203
      Top = 112
      Width = 89
      Height = 25
      Caption = 'XBIZ2PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object XVAL2PANEL: TPanel
      Left = 8
      Top = 112
      Width = 41
      Height = 25
      Caption = 'EUR'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
    end
    object XSUM2PANEL: TPanel
      Left = 56
      Top = 112
      Width = 80
      Height = 25
      Caption = 'XSUM2PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
    object XARF2PANEL: TPanel
      Left = 140
      Top = 112
      Width = 60
      Height = 25
      Caption = 'XARF2PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 12
    end
    object XVAL3PANEL: TPanel
      Left = 8
      Top = 144
      Width = 41
      Height = 25
      Caption = 'EUR'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 13
    end
    object XSUM3PANEL: TPanel
      Left = 56
      Top = 144
      Width = 80
      Height = 25
      Caption = 'XSUM3PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 14
    end
    object XARF3PANEL: TPanel
      Left = 140
      Top = 144
      Width = 60
      Height = 25
      Caption = 'XARF3PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 15
    end
    object XBIZ3PANEL: TPanel
      Left = 203
      Top = 144
      Width = 89
      Height = 25
      Caption = 'XBIZ3PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 16
    end
    object XVAL4PANEL: TPanel
      Left = 8
      Top = 176
      Width = 41
      Height = 25
      Caption = 'AUD'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 17
    end
    object XSUM4PANEL: TPanel
      Left = 56
      Top = 176
      Width = 80
      Height = 25
      Caption = 'XSUM4PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 18
    end
    object XARF4PANEL: TPanel
      Left = 140
      Top = 176
      Width = 60
      Height = 25
      Caption = 'XARF4PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 19
    end
    object XBIZ4PANEL: TPanel
      Left = 203
      Top = 176
      Width = 89
      Height = 25
      Caption = 'XBIZ4PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 20
    end
    object XSUM5PANEL: TPanel
      Left = 56
      Top = 208
      Width = 80
      Height = 25
      Caption = 'XSUM5PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 21
    end
    object XSUM6PANEL: TPanel
      Left = 56
      Top = 240
      Width = 80
      Height = 25
      Caption = 'XSUM6PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 22
    end
    object XSUM7PANEL: TPanel
      Left = 56
      Top = 272
      Width = 80
      Height = 25
      Caption = 'XSUM7PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 23
    end
    object XSUM8PANEL: TPanel
      Left = 56
      Top = 304
      Width = 80
      Height = 25
      Caption = 'XSUM8PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 24
    end
    object XSUM9PANEL: TPanel
      Left = 56
      Top = 336
      Width = 80
      Height = 25
      Caption = 'XSUM9PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 25
    end
    object XSUM10PANEL: TPanel
      Left = 56
      Top = 368
      Width = 80
      Height = 25
      Caption = 'XSUM10PANEL'
      Color = clCream
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 26
    end
    object XARF5PANEL: TPanel
      Left = 140
      Top = 208
      Width = 60
      Height = 25
      Caption = 'XARF5PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 27
    end
    object XARF6PANEL: TPanel
      Left = 140
      Top = 240
      Width = 60
      Height = 25
      Caption = 'XARF6PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 28
    end
    object XARF7PANEL: TPanel
      Left = 140
      Top = 272
      Width = 60
      Height = 25
      Caption = 'XARF7PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 29
    end
    object XARF8PANEL: TPanel
      Left = 140
      Top = 304
      Width = 60
      Height = 25
      Caption = 'XARF8PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 30
    end
    object XARF9PANEL: TPanel
      Left = 140
      Top = 336
      Width = 60
      Height = 25
      Caption = 'XARF9PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 31
    end
    object XARF10PANEL: TPanel
      Left = 140
      Top = 368
      Width = 60
      Height = 25
      Caption = 'XARF10PANEL'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 32
    end
    object XBIZ5PANEL: TPanel
      Left = 203
      Top = 208
      Width = 89
      Height = 25
      Caption = 'XBIZ5PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 33
    end
    object XVAL5PANEL: TPanel
      Left = 8
      Top = 208
      Width = 41
      Height = 25
      Caption = 'USD'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 34
    end
    object XVAL6PANEL: TPanel
      Left = 8
      Top = 240
      Width = 41
      Height = 25
      Caption = 'EUR'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 35
    end
    object XBIZ6PANEL: TPanel
      Left = 203
      Top = 240
      Width = 89
      Height = 25
      Caption = 'XBIZ6PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 36
    end
    object XBIZ7PANEL: TPanel
      Left = 203
      Top = 272
      Width = 89
      Height = 25
      Caption = 'XBIZ7PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 37
    end
    object XBIZ8PANEL: TPanel
      Left = 203
      Top = 304
      Width = 89
      Height = 25
      Caption = 'XBIZ8PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 38
    end
    object XVAL7PANEL: TPanel
      Left = 8
      Top = 272
      Width = 41
      Height = 25
      Caption = 'EUR'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 39
    end
    object XVAL8PANEL: TPanel
      Left = 8
      Top = 304
      Width = 41
      Height = 25
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 40
    end
    object XVAL9PANEL: TPanel
      Left = 8
      Top = 336
      Width = 41
      Height = 25
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 41
    end
    object XVAL10PANEL: TPanel
      Left = 8
      Top = 368
      Width = 41
      Height = 25
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 42
    end
    object XBIZ9PANEL: TPanel
      Left = 203
      Top = 336
      Width = 89
      Height = 25
      Caption = 'XBIZ9PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 43
    end
    object XBIZ10PANEL: TPanel
      Left = 203
      Top = 368
      Width = 89
      Height = 25
      Caption = 'XBIZ10PANEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 44
    end
  end
  object ZAROPANEL: TPanel
    Left = 8
    Top = 8
    Width = 353
    Height = 121
    TabOrder = 5
    object ZFORINTPANEL: TPanel
      Left = 8
      Top = 88
      Width = 112
      Height = 25
      Caption = '123 456 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object Panel151: TPanel
      Left = 8
      Top = 64
      Width = 112
      Height = 25
      Caption = 'Forint'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object Panel152: TPanel
      Left = 8
      Top = 38
      Width = 337
      Height = 25
      Caption = #214'sszesen z'#225'r'#243' k'#233'szlet F9'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object DATUMPANEL: TPanel
      Left = 8
      Top = 8
      Width = 97
      Height = 25
      Caption = '2008.10.31'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object UZLETNEVPANEL: TPanel
      Left = 112
      Top = 8
      Width = 233
      Height = 25
      Caption = 'Ny'#237'regyh'#225'za TESCO'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object Panel155: TPanel
      Left = 120
      Top = 64
      Width = 112
      Height = 24
      Caption = 'Valuta'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object ZVALUTAPANEL: TPanel
      Left = 120
      Top = 88
      Width = 112
      Height = 25
      Caption = '345 000 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object ZOSSZESPANEL: TPanel
      Left = 232
      Top = 88
      Width = 113
      Height = 25
      Caption = '654 230 000 Ft'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object Panel158: TPanel
      Left = 232
      Top = 64
      Width = 113
      Height = 25
      Caption = #214'sszesen'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
  end
  object FORGALOMPANEL: TPanel
    Left = 368
    Top = 8
    Width = 337
    Height = 169
    TabOrder = 6
    object VSUMPANEL: TPanel
      Left = 8
      Top = 136
      Width = 161
      Height = 25
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clPurple
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object Label5: TLabel
        Left = 2
        Top = 6
        Width = 39
        Height = 16
        Caption = #214'ssz:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object NAPIVETELlABEL: TLabel
        Left = 50
        Top = 4
        Width = 98
        Height = 18
        Caption = '123 456 789 Ft'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object ESUMPANEL: TPanel
      Left = 176
      Top = 136
      Width = 153
      Height = 25
      Color = clWhite
      TabOrder = 1
      object Label6: TLabel
        Left = 8
        Top = 6
        Width = 39
        Height = 16
        Caption = #214'ssz:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object NAPIELADASLABEL: TLabel
        Left = 50
        Top = 4
        Width = 98
        Height = 18
        Caption = '123 456 789 Ft'
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = True
      end
    end
    object Panel162: TPanel
      Left = 8
      Top = 40
      Width = 161
      Height = 25
      Caption = 'V'#201'TEL'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel163: TPanel
      Left = 176
      Top = 40
      Width = 153
      Height = 25
      Caption = 'ELAD'#193'S'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object VDEPANEL: TPanel
      Left = 8
      Top = 72
      Width = 161
      Height = 25
      Color = clAqua
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      object Label1: TLabel
        Left = 8
        Top = 6
        Width = 23
        Height = 16
        Caption = 'de:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DEVETLABEL: TLabel
        Left = 40
        Top = 6
        Width = 108
        Height = 19
        Caption = '345 000 000 Ft'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object VDUPANEL: TPanel
      Left = 8
      Top = 104
      Width = 161
      Height = 25
      Color = clAqua
      TabOrder = 5
      object Label3: TLabel
        Left = 8
        Top = 6
        Width = 22
        Height = 16
        Caption = 'du:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DUVETLABEL: TLabel
        Left = 40
        Top = 6
        Width = 108
        Height = 19
        Caption = '123 456 700 Ft'
        Color = clCream
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        Transparent = True
      end
    end
    object EDEPANEL: TPanel
      Left = 176
      Top = 72
      Width = 153
      Height = 25
      Color = clAqua
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      object Label2: TLabel
        Left = 8
        Top = 6
        Width = 23
        Height = 16
        Caption = 'de:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DEELADASLABEL: TLabel
        Left = 40
        Top = 6
        Width = 77
        Height = 19
        Caption = '300 000 Ft'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object EDUPANEL: TPanel
      Left = 176
      Top = 104
      Width = 153
      Height = 25
      Color = clAqua
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      object Label4: TLabel
        Left = 8
        Top = 6
        Width = 22
        Height = 16
        Caption = 'du:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DUELADASLABEL: TLabel
        Left = 40
        Top = 6
        Width = 108
        Height = 19
        Caption = '400 000 000 Ft'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object Panel168: TPanel
      Left = 8
      Top = 8
      Width = 321
      Height = 25
      Caption = 'NAPI FORGALOM'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
  end
  object PROSNEVPANEL: TPanel
    Left = 720
    Top = 664
    Width = 305
    Height = 81
    TabOrder = 9
    object Panel171: TPanel
      Left = 8
      Top = 16
      Width = 89
      Height = 25
      Caption = 'Pt'#225'ros: de:'
      Color = clAqua
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object Panel172: TPanel
      Left = 8
      Top = 48
      Width = 89
      Height = 25
      Caption = 'Pt'#225'ros: du:'
      Color = clAqua
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object DEPROSNEVPANEL: TPanel
      Left = 104
      Top = 16
      Width = 193
      Height = 25
      Caption = 'Kalocsai Adrienn'
      Color = 9502719
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object DUPROSNEVPANEL: TPanel
      Left = 104
      Top = 48
      Width = 193
      Height = 25
      Caption = 'Zalaegerszegi Katalin'
      Color = 9502719
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
  end
  object KULDOKPANEL: TPanel
    Left = 368
    Top = 424
    Width = 337
    Height = 121
    Caption = 'KULDOKPANEL'
    TabOrder = 11
    object Label10: TLabel
      Left = 8
      Top = 4
      Width = 69
      Height = 18
      Caption = 'K'#220'LD'#214'K:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object MemoKULDOK: TMemo
    Left = 368
    Top = 448
    Width = 335
    Height = 97
    Cursor = crHandPoint
    Lines.Strings = (
      '')
    TabOrder = 8
    OnEnter = MEMOKEREKEnter
    OnExit = MEMOKEREKExit
  end
  object KEREKPANEL: TPanel
    Left = 712
    Top = 424
    Width = 297
    Height = 121
    Caption = 'KEREKPANEL'
    TabOrder = 12
    object Label11: TLabel
      Left = 16
      Top = 4
      Width = 57
      Height = 18
      Caption = 'K'#201'REK:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object MEMOKEREK: TMemo
    Left = 714
    Top = 448
    Width = 293
    Height = 97
    Cursor = crHandPoint
    TabOrder = 7
    OnEnter = MEMOKEREKEnter
    OnExit = MEMOKEREKExit
  end
  object FUGGONY: TPanel
    Left = -1850
    Top = 8
    Width = 1017
    Height = 737
    BevelOuter = bvNone
    Color = clYellow
    TabOrder = 13
    object Label7: TLabel
      Left = 128
      Top = 256
      Width = 832
      Height = 43
      Caption = 'NAPI JELENT'#201'S ELK'#201'SZ'#205'T'#201'SE '#201'S BEK'#220'LD'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object INDITOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = INDITOTIMERTimer
    Left = 256
    Top = 480
  end
  object BFTABLA: TIBTable
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'BIZONYLATSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 7
      end
      item
        Name = 'TIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 11
      end
      item
        Name = 'IDO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 8
      end
      item
        Name = 'OSSZESFORINTERTEK'
        DataType = ftInteger
      end
      item
        Name = 'UGYFELTIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'UGYFELSZAM'
        DataType = ftInteger
      end
      item
        Name = 'UGYFELNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'TETEL'
        DataType = ftSmallint
      end
      item
        Name = 'PENZTAROSNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'TARSPENZTARKOD'
        Attributes = [faFixed]
        DataType = ftString
        Size = 4
      end
      item
        Name = 'TRBPENZTAR'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'MEGBIZOSZAM'
        DataType = ftInteger
      end
      item
        Name = 'MEGBIZOTT'
        DataType = ftInteger
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end
      item
        Name = 'STORNOZOTTBIZONYLAT'
        Attributes = [faFixed]
        DataType = ftString
        Size = 7
      end
      item
        Name = 'STORNOBIZONYLAT'
        Attributes = [faFixed]
        DataType = ftString
        Size = 7
      end>
    IndexDefs = <
      item
        Name = 'XBF0810'
        Fields = 'DATUM'
      end>
    StoreDefs = True
    TableName = 'BF0810'
    Left = 720
    Top = 504
  end
  object BFDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 784
    Top = 504
  end
  object BFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 816
    Top = 504
  end
  object BTTABLA: TIBTable
    Database = BTDBASE
    Transaction = BTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'BIZONYLATSZAM'
        DataType = ftString
        Size = 7
      end
      item
        Name = 'VALUTANEM'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'ELSZAMOLASIARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'BANKJEGY'
        DataType = ftInteger
      end
      item
        Name = 'FORINTERTEK'
        DataType = ftInteger
      end
      item
        Name = 'ELOJEL'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'COIN'
        DataType = ftSmallint
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'XBT0810'
        Fields = 'BIZONYLATSZAM'
      end>
    StoreDefs = True
    TableName = 'BT0810'
    Left = 720
    Top = 472
  end
  object BTDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 784
    Top = 472
  end
  object BTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BTDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 816
    Top = 472
  end
  object FejSource: TDataSource
    DataSet = BFTABLA
    Left = 848
    Top = 504
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 240
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 240
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 120
    Top = 240
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 272
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 272
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 120
    Top = 272
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 272
  end
  object BFQUERY: TIBQuery
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 752
    Top = 504
  end
  object BTQUERY: TIBQuery
    Database = BTDBASE
    Transaction = BTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 752
    Top = 472
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 872
    Top = 432
  end
  object TRADEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 904
    Top = 432
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 936
    Top = 432
  end
  object PILLQUERY: TIBQuery
    Database = PILLDBASE
    Transaction = PILLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'select * FROM NAPIZAR')
    Left = 16
    Top = 496
    object PILLQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'NAPIZAR.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object PILLQUERYZARO: TIntegerField
      FieldName = 'ZARO'
      Origin = 'NAPIZAR.ZARO'
    end
    object PILLQUERYVETEL: TIntegerField
      FieldName = 'VETEL'
      Origin = 'NAPIZAR.VETEL'
    end
    object PILLQUERYELADAS: TIntegerField
      FieldName = 'ELADAS'
      Origin = 'NAPIZAR.ELADAS'
    end
  end
  object PILLDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PILLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 496
  end
  object PILLTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = PILLDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 496
  end
  object PILLSOURCE: TDataSource
    DataSet = PILLQUERY
    Left = 112
    Top = 496
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 304
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 304
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 308
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 288
    Top = 480
  end
end
