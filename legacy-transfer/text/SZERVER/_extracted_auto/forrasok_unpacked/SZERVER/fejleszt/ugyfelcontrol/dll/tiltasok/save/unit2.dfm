object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 476
  ClientWidth = 977
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object LISTAPANEL: TPanel
    Left = -1999
    Top = 24
    Width = 871
    Height = 433
    Hint = '36'
    BevelOuter = bvNone
    Caption = ' '
    Color = clSilver
    TabOrder = 1
    Visible = False
    object TIPUSVALASZTOPANEL: TPanel
      Left = 100
      Top = 40
      Width = 481
      Height = 201
      BevelOuter = bvNone
      Color = clSilver
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      Visible = False
      object Shape2: TShape
        Left = 24
        Top = 152
        Width = 441
        Height = 40
        Pen.Width = 2
        Shape = stRoundRect
      end
      object Label2: TLabel
        Left = 96
        Top = 96
        Width = 299
        Height = 21
        Caption = 'TILTOTT SZEM'#201'LYEK TIPUSA'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Cooper Black'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object NATURGOMB: TBitBtn
        Left = 32
        Top = 160
        Width = 137
        Height = 25
        Cursor = crHandPoint
        Caption = 'TERM'#201'SZETES SZEM'#201'LY'
        TabOrder = 0
        OnClick = NATURGOMBClick
      end
      object jogigomb: TBitBtn
        Left = 176
        Top = 160
        Width = 137
        Height = 25
        Cursor = crHandPoint
        Caption = 'JOGI SZEM'#201'LY'
        TabOrder = 1
        OnClick = jogigombClick
      end
      object MEGSEMGOMB: TBitBtn
        Left = 320
        Top = 160
        Width = 137
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        TabOrder = 2
        OnClick = MEGSEMGOMBClick
      end
    end
    object ATHOZOPANEL: TPanel
      Left = -1789
      Top = 40
      Width = 673
      Height = 380
      BevelOuter = bvNone
      TabOrder = 1
      Visible = False
      object Shape3: TShape
        Left = 0
        Top = 0
        Width = 673
        Height = 380
        Align = alClient
        Brush.Color = 11599871
        Pen.Color = clRed
        Pen.Width = 2
      end
      object Label4: TLabel
        Left = 32
        Top = 24
        Width = 593
        Height = 21
        Caption = 'AZ '#214'SSZES LETILTOTT SZEM'#201'LY '#193'THOZ'#193'SA AZ IDEI '#201'VRE'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object Label5: TLabel
        Left = 104
        Top = 64
        Width = 204
        Height = 23
        Caption = 'M'#218'LT '#201'VBEN LETILTOTTAK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object Label6: TLabel
        Left = 400
        Top = 64
        Width = 184
        Height = 23
        Caption = 'AZ IDEI '#201'V LETILTOTTJAI'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object LOCMEMO: TMemo
        Left = 96
        Top = 88
        Width = 217
        Height = 209
        BorderStyle = bsNone
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 0
      end
      object REMMEMO: TMemo
        Left = 384
        Top = 88
        Width = 217
        Height = 201
        BorderStyle = bsNone
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 1
      end
      object ATHOZSTARTGOMB: TBitBtn
        Left = 168
        Top = 344
        Width = 145
        Height = 25
        Cursor = crHandPoint
        Caption = #193'THOZ'#193'S INDUL'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
      end
      object ATHOZMEGSEMGOMB: TBitBtn
        Left = 384
        Top = 344
        Width = 145
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A MEN'#220'RE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = ATHOZMEGSEMGOMBClick
      end
      object CSIK: TProgressBar
        Left = 32
        Top = 312
        Width = 617
        Height = 17
        Min = 0
        Max = 26
        Smooth = True
        Step = 1
        TabOrder = 4
      end
    end
    object NATURLISTAZOPANEL: TPanel
      Left = -1898
      Top = 8
      Width = 873
      Height = 417
      TabOrder = 2
      Visible = False
      object Panel1: TPanel
        Left = 8
        Top = 8
        Width = 857
        Height = 33
        Caption = 'A LETILTOTT TERM'#201'SZETES SZEM'#201'LYEK LIST'#193'JA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object NATURRACS: TDBGrid
        Left = 8
        Top = 48
        Width = 857
        Height = 329
        DataSource = NATURSOURCE
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = NATURRACSCellClick
        OnDblClick = NATURRACSDblClick
        OnKeyUp = NATURRACSKeyUp
        Columns = <
          item
            Expanded = False
            FieldName = 'NEV'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L NEVE'
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 154
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ANYJANEVE'
            Title.Alignment = taCenter
            Title.Caption = 'ANYJA NEVE'
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 143
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'SZULETESIHELY'
            Title.Alignment = taCenter
            Title.Caption = 'SZ'#220'LET'#201'SI HELY'
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 149
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'SZULETESIIDO'
            Title.Alignment = taCenter
            Title.Caption = 'SZ'#220'L-I ID'#336
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'LAKCIM'
            Title.Alignment = taCenter
            Title.Caption = 'AZ '#220'GYF'#201'L LAKC'#205'ME'
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Visible = True
          end>
      end
      object NATURVISSZAVONOGOMB: TBitBtn
        Left = 8
        Top = 384
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'TILT'#193'S VISSZAVON'#193'SA -->'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = NATURVISSZAVONOGOMBClick
      end
      object NATURLISTAVISSZAGOMB: TBitBtn
        Left = 664
        Top = 384
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A F'#336'MEN'#220'RE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = NATURLISTAVISSZAGOMBClick
      end
      object NATURNEVEDIT: TEdit
        Left = 208
        Top = 384
        Width = 193
        Height = 27
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        Text = ' '
      end
      object CSAKFORRASPANEL: TPanel
        Left = 408
        Top = 384
        Width = 249
        Height = 25
        BevelOuter = bvNone
        Caption = 'CSAK P'#201'NZESZK'#214'Z  FORR'#193'SSAL'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
        Visible = False
      end
    end
    object LEVALOGATOPANEL: TPanel
      Left = -1987
      Top = 130
      Width = 521
      Height = 89
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 3
      Visible = False
      object Shape4: TShape
        Left = 0
        Top = 0
        Width = 521
        Height = 89
        Align = alClient
        Pen.Color = clRed
        Pen.Width = 3
      end
      object LEVALCIMPANEL: TPanel
        Left = 8
        Top = 16
        Width = 505
        Height = 25
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object LEVALCSIK: TProgressBar
        Left = 8
        Top = 56
        Width = 505
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 1
      end
    end
    object JOGILISTAZOPANEL: TPanel
      Left = -1987
      Top = 8
      Width = 873
      Height = 417
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      Visible = False
      object JOGIRACS: TDBGrid
        Left = 8
        Top = 48
        Width = 857
        Height = 329
        DataSource = JOGISOURCE
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        ParentFont = False
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = JOGIRACSCellClick
        OnDblClick = JOGIRACSDblClick
        OnKeyUp = JOGIRACSKeyUp
        Columns = <
          item
            Expanded = False
            FieldName = 'JOGISZEMELYNEV'
            Title.Alignment = taCenter
            Title.Caption = 'MEGNEVEZ'#201'S'
            Title.Color = 11599871
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 203
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TELEPHELYCIM'
            Title.Alignment = taCenter
            Title.Caption = 'TELEPHELY CIME'
            Title.Color = 11599871
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 238
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FOTEVEKENYSEG'
            Title.Alignment = taCenter
            Title.Caption = 'F'#336' TEV'#201'KENYS'#201'G'
            Title.Color = 11599871
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 186
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'MEGBIZOTTNEVE'
            Title.Alignment = taCenter
            Title.Caption = 'MEGBIZOTT NEVE'
            Title.Color = 11599871
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold, fsItalic]
            Visible = True
          end>
      end
      object Panel2: TPanel
        Left = 8
        Top = 8
        Width = 857
        Height = 33
        Caption = 'A LETILTOTT JOGI SZEM'#201'LYEK LIST'#193'JA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object JOGIVISSZAVONOGOMB: TBitBtn
        Left = 8
        Top = 384
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'TILT'#193'S VISSZAVON'#193'SA --->'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = JOGIVISSZAVONOGOMBClick
      end
      object JOGILISTAVISSZAGOMB: TBitBtn
        Left = 656
        Top = 384
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A F'#336'MEN'#220'RE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = JOGILISTAVISSZAGOMBClick
      end
      object JOGINEVEDIT: TEdit
        Left = 208
        Top = 384
        Width = 417
        Height = 25
        BorderStyle = bsNone
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        Text = ' '
      end
    end
    object NATURKIVALASZTOPANEL: TPanel
      Left = 8
      Top = 8
      Width = 855
      Height = 417
      TabOrder = 5
      Visible = False
      object NATVALDATAIN: TPanel
        Left = -1987
        Top = 64
        Width = 433
        Height = 289
        Color = clSilver
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        Visible = False
        object Label7: TLabel
          Left = 16
          Top = 16
          Width = 409
          Height = 23
          Caption = 'V'#193'LASZD KI A LETILTAND'#211' TERM'#201'SZETES  SZEM'#201'LYT '
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object Label8: TLabel
          Left = 40
          Top = 58
          Width = 94
          Height = 19
          Caption = #220'GYF'#201'L NEVE:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object Label9: TLabel
          Left = 48
          Top = 92
          Width = 87
          Height = 19
          Caption = 'ANYJA NEVE:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object Label10: TLabel
          Left = 32
          Top = 124
          Width = 106
          Height = 19
          Caption = 'SZ'#220'LET'#201'SI HELY:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object Label11: TLabel
          Left = 32
          Top = 156
          Width = 100
          Height = 19
          Caption = 'SZ'#220'LET'#201'SI ID'#336':'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object NEVEDIT: TEdit
          Left = 144
          Top = 56
          Width = 257
          Height = 27
          CharCase = ecUpperCase
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          MaxLength = 50
          ParentFont = False
          TabOrder = 0
          Text = 'ASDFGERTZ ASDFGTREW ASWDEFRTG ASDFER54TZ '
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = NEVEDITKeyDown
        end
        object ANYJAEDIT: TEdit
          Left = 144
          Top = 88
          Width = 257
          Height = 27
          CharCase = ecUpperCase
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          MaxLength = 50
          ParentFont = False
          TabOrder = 1
          Text = 'ANYJAEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = ANYJAEDITKeyDown
        end
        object SZULHELYEDIT: TEdit
          Left = 144
          Top = 120
          Width = 257
          Height = 27
          CharCase = ecUpperCase
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          MaxLength = 40
          ParentFont = False
          TabOrder = 2
          Text = 'SZULHELYEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = SZULHELYEDITKeyDown
        end
        object SZULIDOEDIT: TEdit
          Left = 144
          Top = 152
          Width = 89
          Height = 27
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          MaxLength = 10
          ParentFont = False
          TabOrder = 3
          Text = '1991.11.12'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = SZULIDOEDITKeyDown
        end
        object NATVALOKEGOMB: TBitBtn
          Left = 264
          Top = 155
          Width = 137
          Height = 25
          Cursor = crHandPoint
          Caption = 'ADATOK RENDBEN'
          TabOrder = 4
          OnClick = NATVALOKEGOMBClick
        end
        object NATVALMEGSEMGOMB: TBitBtn
          Left = 336
          Top = 248
          Width = 81
          Height = 25
          Cursor = crHandPoint
          Caption = 'M'#201'GSEM'
          TabOrder = 5
          OnClick = NATVALMEGSEMGOMBClick
        end
        object LAKCIMPANEL: TPanel
          Left = 24
          Top = 192
          Width = 401
          Height = 33
          BevelOuter = bvNone
          Color = clSilver
          TabOrder = 6
          Visible = False
          object Label12: TLabel
            Left = 0
            Top = 8
            Width = 55
            Height = 19
            Caption = 'LAKCIM:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Calibri'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            Transparent = True
          end
          object LAKCIMEDIT: TEdit
            Left = 60
            Top = 10
            Width = 337
            Height = 23
            BorderStyle = bsNone
            Color = clSilver
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Calibri'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
        end
        object NATLETILTOGOMB: TBitBtn
          Left = 16
          Top = 248
          Width = 121
          Height = 25
          Cursor = crHandPoint
          Caption = 'V'#193'LT'#193'S LETILT'#193'SA'
          TabOrder = 7
          OnClick = NATLETILTOGOMBClick
        end
        object PENZFORRASGOMB: TBitBtn
          Left = 144
          Top = 248
          Width = 185
          Height = 25
          Cursor = crHandPoint
          Caption = 'CSAK P'#201'NZFORR'#193'SSAL V'#193'LTHAT'
          TabOrder = 8
          OnClick = PENZFORRASGOMBClick
        end
        object GOMBTAKAROPANEL: TPanel
          Left = 8
          Top = 240
          Width = 417
          Height = 41
          BevelOuter = bvNone
          Color = clSilver
          TabOrder = 9
        end
      end
    end
    object JOGIKIVALASZTOPANEL: TPanel
      Left = -1999
      Top = 8
      Width = 873
      Height = 417
      TabOrder = 6
      Visible = False
      object JOGIVALDATAIN: TPanel
        Left = -1987
        Top = 56
        Width = 457
        Height = 313
        Color = clSilver
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        Visible = False
        object Label13: TLabel
          Left = 64
          Top = 24
          Width = 365
          Height = 26
          Caption = 'V'#193'LASZD KI A LETILTAND'#211' JOGI SZEM'#201'LYT'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -21
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
        end
        object Label14: TLabel
          Left = 40
          Top = 72
          Width = 135
          Height = 19
          Caption = 'JOGI SZEM'#201'LY NEVE:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object Label15: TLabel
          Left = 56
          Top = 104
          Width = 113
          Height = 19
          Caption = 'TELEPHELY C'#205'ME:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object Label16: TLabel
          Left = 40
          Top = 136
          Width = 135
          Height = 19
          Caption = 'F'#220#336' TEV'#201'KENYS'#201'GE:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object Label17: TLabel
          Left = 72
          Top = 168
          Width = 102
          Height = 19
          Caption = 'OKIRAT SZ'#193'MA:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object Label18: TLabel
          Left = 48
          Top = 200
          Width = 122
          Height = 19
          Caption = 'MEGBIZOTT NEVE:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object JNEVEDIT: TEdit
          Left = 176
          Top = 72
          Width = 265
          Height = 23
          CharCase = ecUpperCase
          TabOrder = 0
          Text = 'JNEVEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = JNEVEDITKeyDown
        end
        object JTELEPHELYEDIT: TEdit
          Left = 176
          Top = 104
          Width = 265
          Height = 23
          CharCase = ecUpperCase
          TabOrder = 1
          Text = 'JTELEPHELYEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = JTELEPHELYEDITKeyDown
        end
        object JFOTEVEDIT: TEdit
          Left = 176
          Top = 136
          Width = 265
          Height = 23
          CharCase = ecUpperCase
          TabOrder = 2
          Text = 'JFOTEVEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = JFOTEVEDITKeyDown
        end
        object JOKIRATEDIT: TEdit
          Left = 176
          Top = 168
          Width = 265
          Height = 23
          CharCase = ecUpperCase
          TabOrder = 3
          Text = 'JOKIRATEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = JOKIRATEDITKeyDown
        end
        object JMBNEVEDIT: TEdit
          Left = 176
          Top = 200
          Width = 265
          Height = 23
          CharCase = ecUpperCase
          TabOrder = 4
          Text = 'JMBNEVEDIT'
          OnEnter = NEVEDITEnter
          OnExit = NEVEDITExit
          OnKeyDown = JMBNEVEDITKeyDown
        end
        object JOGILETILTOGOMB: TBitBtn
          Left = 32
          Top = 272
          Width = 193
          Height = 25
          Caption = 'EZT A JOGI SZEM'#201'LYT TILTJUK LE'
          Enabled = False
          TabOrder = 5
          OnClick = JOGILETILTOGOMBClick
        end
        object JOGIVALMEGSEMGOMB: TBitBtn
          Left = 232
          Top = 272
          Width = 193
          Height = 25
          Cursor = crHandPoint
          Caption = 'M'#201'GSEM'
          TabOrder = 6
        end
        object JOGIJELZOPANEL: TPanel
          Left = 16
          Top = 264
          Width = 209
          Height = 41
          Caption = 'LETILT'#193'S !!'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clRed
          Font.Height = -24
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
          TabOrder = 7
          Visible = False
        end
        object JOGIDATAOKEGOMB: TBitBtn
          Left = 176
          Top = 232
          Width = 161
          Height = 25
          Cursor = crHandPoint
          Caption = 'ADATOK RENDBEN'
          TabOrder = 8
          OnClick = JOGIDATAOKEGOMBClick
        end
      end
    end
  end
  object TILTOMENUPANEL: TPanel
    Left = -1999
    Top = 80
    Width = 369
    Height = 225
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Calibri'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    Visible = False
    object Label1: TLabel
      Left = 72
      Top = 16
      Width = 230
      Height = 36
      Caption = 'TILT'#193'SOK KEZEL'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Gill Sans Ultra Bold Condensed'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object LISTAGOMB: TPanel
      Left = 32
      Top = 72
      Width = 320
      Height = 25
      Cursor = crHandPoint
      Caption = 'LETILTOTT '#220'GYFELEK LIST'#193'JA, FELOLD'#193'SA'
      TabOrder = 0
      OnClick = LISTAGOMBClick
    end
    object LETILTOGOMB: TPanel
      Left = 32
      Top = 104
      Width = 320
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYFELEK LETILT'#193'SA'
      TabOrder = 1
      OnClick = LETILTOGOMBClick
    end
    object ATHOZOGOMB: TPanel
      Left = 32
      Top = 136
      Width = 320
      Height = 25
      Cursor = crHandPoint
      Caption = 'LETILTOTT '#220'GYFELEK '#193'THOZ'#193'SA EL'#214'Z'#336' '#201'VB'#214'L'
      TabOrder = 2
      OnClick = ATHOZOGOMBClick
    end
    object VISSZAGOMB: TPanel
      Left = 32
      Top = 168
      Width = 320
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
  end
  object LETILTOPANEL: TPanel
    Left = -1987
    Top = 168
    Width = 465
    Height = 201
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 465
      Height = 201
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label3: TLabel
      Left = 136
      Top = 16
      Width = 233
      Height = 21
      Caption = #220'GYFELEK LETILT'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object YEARGOMB: TPanel
      Left = 160
      Top = 64
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = YEARGOMBClick
    end
    object LASTYEARGOMB: TPanel
      Left = 240
      Top = 64
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = LASTYEARGOMBClick
    end
    object TNATURGOMB: TPanel
      Left = 64
      Top = 96
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'TERM'#201'SZETES SZEM'#201'LY'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = TNATURGOMBClick
    end
    object TJOGIGOMB: TPanel
      Left = 240
      Top = 96
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'JOGI SZEM'#201'LY'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = TJOGIGOMBClick
    end
    object TRENDBENGOMB: TBitBtn
      Left = 120
      Top = 144
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = TRENDBENGOMBClick
    end
    object TMEGSEMGOMB: TBitBtn
      Left = 240
      Top = 144
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = TMEGSEMGOMBClick
    end
  end
  object LOCQUERY: TIBQuery
    Database = LOCDBASE
    Transaction = LOCTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 736
    Top = 256
  end
  object LOCDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = LOCTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 768
    Top = 256
  end
  object LOCTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = LOCDBASE
    AutoStopAction = saNone
    Left = 800
    Top = 256
  end
  object REMQUERY: TIBQuery
    Database = REMDBASE
    Transaction = REMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 736
    Top = 216
  end
  object REMDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 768
    Top = 216
  end
  object REMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMDBASE
    AutoStopAction = saNone
    Left = 800
    Top = 216
  end
  object NATURSOURCE: TDataSource
    DataSet = LOCQUERY
    Enabled = False
    Left = 736
    Top = 184
  end
  object JOGISOURCE: TDataSource
    DataSet = LOCQUERY
    Left = 768
    Top = 184
  end
end
