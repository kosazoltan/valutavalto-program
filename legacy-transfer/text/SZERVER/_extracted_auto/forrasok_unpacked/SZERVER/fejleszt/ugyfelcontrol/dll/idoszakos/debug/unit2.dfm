object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 539
  ClientWidth = 1000
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
    Left = 0
    Top = 0
    Width = 993
    Height = 537
    Color = clWhite
    TabOrder = 0
    object Panel2: TPanel
      Left = 6
      Top = 2
      Width = 985
      Height = 41
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 0
      object LIMITPANEL: TPanel
        Left = 2
        Top = 2
        Width = 200
        Height = 37
        BevelOuter = bvNone
        Caption = '2022 szeptember 14-18'
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object PENZTARPANEL: TPanel
        Left = 204
        Top = 2
        Width = 234
        Height = 37
        BevelOuter = bvNone
        Caption = '43. H'#243'dmez'#337'v'#225's'#225'rhely TESCO'
        Color = 11599871
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object SZUROGOMB: TPanel
        Left = 440
        Top = 2
        Width = 200
        Height = 37
        Cursor = crHandPoint
        BevelOuter = bvNone
        Caption = 'Sorbarendez'#233's - Adatsz'#369'r'#233's'
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = SZUROGOMBClick
      end
      object VISSZAGOMB: TPanel
        Left = 804
        Top = 2
        Width = 178
        Height = 37
        Cursor = crHandPoint
        BevelOuter = bvNone
        Caption = 'Vissza a men'#369're'
        Color = 11599871
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = VISSZAGOMBClick
      end
      object Panel10: TPanel
        Left = 642
        Top = 2
        Width = 159
        Height = 37
        Cursor = crHandPoint
        BevelOuter = bvNone
        Caption = 'Excel k'#233'sz'#237't'#233'se'
        Color = 11599871
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 4
        OnClick = Panel10Click
      end
    end
    object RACSPANEL: TPanel
      Left = 4
      Top = 48
      Width = 985
      Height = 473
      BevelOuter = bvNone
      Color = 16311512
      TabOrder = 1
      object Label29: TLabel
        Left = 16
        Top = 416
        Width = 87
        Height = 18
        Caption = 'SORREND:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label31: TLabel
        Left = 16
        Top = 442
        Width = 87
        Height = 18
        Caption = 'FELT'#201'TEL:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object FEJRACS: TDBGrid
        Left = 8
        Top = 8
        Width = 537
        Height = 401
        DataSource = FEJSOURCE
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = FejRacsCellClick
        OnDblClick = FejRacsDblClick
        OnKeyUp = FejRacsKeyUp
        Columns = <
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'BIZONYLATSZAM'
            Title.Alignment = taCenter
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -12
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 130
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'DATUM'
            Title.Alignment = taCenter
            Title.Caption = 'D'#193'TUM'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -12
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 101
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'IDO'
            Title.Alignment = taCenter
            Title.Caption = 'ID'#336
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -12
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 80
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FIZETENDO'
            Title.Alignment = taCenter
            Title.Caption = 'FIZETEND'#336
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -12
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 103
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'KEZELESIDIJ'
            Title.Alignment = taCenter
            Title.Caption = 'KEZ-I D'#205'J'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -12
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold, fsItalic]
            Width = 90
            Visible = True
          end>
      end
      object Panel3: TPanel
        Left = 552
        Top = 64
        Width = 425
        Height = 401
        BevelOuter = bvNone
        Color = clWhite
        TabOrder = 1
        object NATUGYFELPANEL: TPanel
          Left = -1999
          Top = -24
          Width = 409
          Height = 156
          BevelOuter = bvNone
          TabOrder = 0
          Visible = False
          object Label1: TLabel
            Left = 8
            Top = 8
            Width = 244
            Height = 23
            Caption = 'TERM. SZEM'#201'LY '#220'GYF'#201'L'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object Label2: TLabel
            Left = 28
            Top = 58
            Width = 40
            Height = 16
            Caption = 'NEVE:'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label3: TLabel
            Left = 28
            Top = 80
            Width = 87
            Height = 16
            Caption = 'ANYJA NEVE:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label4: TLabel
            Left = 28
            Top = 106
            Width = 72
            Height = 16
            Caption = 'SZ'#220'LET'#201'S:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label5: TLabel
            Left = 24
            Top = 128
            Width = 52
            Height = 16
            Caption = 'LAKC'#205'M:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label21: TLabel
            Left = 320
            Top = 8
            Width = 31
            Height = 19
            Caption = 'ISO:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object DBEdit16: TDBEdit
            Left = 72
            Top = 54
            Width = 329
            Height = 24
            TabStop = False
            DataField = 'NEV'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object DBEdit17: TDBEdit
            Left = 120
            Top = 78
            Width = 281
            Height = 24
            DataField = 'ANYJANEVE'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 1
          end
          object DBEdit18: TDBEdit
            Left = 104
            Top = 102
            Width = 73
            Height = 24
            DataField = 'SZULETESIIDO'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
          end
          object DBEdit19: TDBEdit
            Left = 180
            Top = 102
            Width = 217
            Height = 24
            DataField = 'SZULETESIHELY'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 3
          end
          object DBEdit20: TDBEdit
            Left = 80
            Top = 126
            Width = 313
            Height = 24
            DataField = 'LAKCIM'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 4
          end
          object DBEdit21: TDBEdit
            Left = 354
            Top = 8
            Width = 35
            Height = 24
            DataField = 'ISO'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 5
          end
        end
        object PENZPANEL: TPanel
          Left = 8
          Top = 240
          Width = 409
          Height = 84
          BevelOuter = bvNone
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          ParentFont = False
          TabOrder = 1
          object Label6: TLabel
            Left = 56
            Top = 8
            Width = 158
            Height = 16
            Caption = 'UTOLS'#211' V'#193'LT'#193'S NAPJA:'
          end
          object Label7: TLabel
            Left = 56
            Top = 34
            Width = 155
            Height = 16
            Caption = #201'VI MAXIM'#193'LIS V'#193'LT'#193'S:'
          end
          object Label8: TLabel
            Left = 16
            Top = 58
            Width = 138
            Height = 16
            Caption = #201'VI '#214'SSZES V'#193'LT'#193'S:'
          end
          object DBEdit12: TDBEdit
            Left = 224
            Top = 6
            Width = 73
            Height = 24
            DataField = 'UTOLSOVALTAS'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object DBEdit13: TDBEdit
            Left = 224
            Top = 30
            Width = 97
            Height = 24
            DataField = 'EVIMAX'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 1
          end
          object DBEdit14: TDBEdit
            Left = 160
            Top = 54
            Width = 49
            Height = 24
            DataField = 'VALTASDB'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
          end
          object DBEdit15: TDBEdit
            Left = 224
            Top = 54
            Width = 97
            Height = 24
            DataField = 'OSSZESVALTAS'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 3
          end
        end
        object PTARPANEL: TPanel
          Left = 8
          Top = 328
          Width = 409
          Height = 62
          BevelOuter = bvNone
          TabOrder = 2
          object Label9: TLabel
            Left = 40
            Top = 10
            Width = 65
            Height = 16
            Caption = 'P'#201'NZT'#193'R:'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label10: TLabel
            Left = 16
            Top = 34
            Width = 84
            Height = 16
            Caption = 'P'#201'NZT'#193'ROS:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object DBEdit8: TDBEdit
            Left = 112
            Top = 8
            Width = 33
            Height = 24
            DataField = 'PENZTARSZAM'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object DBEdit9: TDBEdit
            Left = 152
            Top = 8
            Width = 249
            Height = 24
            DataField = 'PENZTARNEV'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 1
          end
          object DBEdit10: TDBEdit
            Left = 112
            Top = 32
            Width = 289
            Height = 24
            DataField = 'PENZTAROSNEV'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
          end
        end
        object JOGIUGYFELPANEL: TPanel
          Left = -999
          Top = 4
          Width = 409
          Height = 237
          BevelOuter = bvNone
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          ParentFont = False
          TabOrder = 3
          Visible = False
          object Label11: TLabel
            Left = 24
            Top = 8
            Width = 187
            Height = 18
            Caption = 'JOGI SZEM'#201'LY '#220'GYF'#201'L'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object Label12: TLabel
            Left = 32
            Top = 40
            Width = 40
            Height = 16
            Caption = 'NEVE:'
          end
          object Label13: TLabel
            Left = 40
            Top = 64
            Width = 36
            Height = 16
            Caption = 'C'#205'ME:'
          end
          object Label14: TLabel
            Left = 24
            Top = 88
            Width = 51
            Height = 16
            Caption = 'OKIRAT:'
          end
          object Label15: TLabel
            Left = 8
            Top = 112
            Width = 66
            Height = 16
            Caption = 'F'#336'TEV'#201'K:'
          end
          object Label16: TLabel
            Left = 8
            Top = 136
            Width = 67
            Height = 16
            Caption = 'MB. NEVE:'
          end
          object Label17: TLabel
            Left = 16
            Top = 160
            Width = 59
            Height = 16
            Caption = 'MB. BEO:'
          end
          object Label18: TLabel
            Left = 24
            Top = 184
            Width = 53
            Height = 16
            Caption = 'K'#201'PVIS:'
          end
          object Label19: TLabel
            Left = 24
            Top = 208
            Width = 54
            Height = 16
            Caption = 'KV BEO:'
          end
          object Label20: TLabel
            Left = 328
            Top = 12
            Width = 31
            Height = 19
            Caption = 'ISO:'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object DBEdit2: TDBEdit
            Left = 80
            Top = 62
            Width = 321
            Height = 24
            DataField = 'TELEPHELYCIM'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object DBEdit3: TDBEdit
            Left = 80
            Top = 86
            Width = 321
            Height = 24
            DataField = 'OKIRATSZAM'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 1
          end
          object DBEdit4: TDBEdit
            Left = 80
            Top = 134
            Width = 321
            Height = 24
            DataField = 'MEGBIZOTTNEVE'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
          end
          object DBEdit5: TDBEdit
            Left = 80
            Top = 158
            Width = 321
            Height = 24
            DataField = 'MBBEO'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 3
          end
          object DBEdit6: TDBEdit
            Left = 80
            Top = 182
            Width = 321
            Height = 24
            DataField = 'KEPVISNEV'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 4
          end
          object DBEdit7: TDBEdit
            Left = 80
            Top = 206
            Width = 321
            Height = 24
            DataField = 'KEPVISBEO'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 5
          end
          object DBEdit1: TDBEdit
            Left = 80
            Top = 38
            Width = 321
            Height = 24
            DataField = 'CEGNEV'
            DataSource = FEJSOURCE
            TabOrder = 6
          end
          object DBEdit11: TDBEdit
            Left = 360
            Top = 10
            Width = 35
            Height = 24
            DataField = 'CEGORSZAG'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 7
          end
          object DBEdit27: TDBEdit
            Left = 80
            Top = 110
            Width = 321
            Height = 24
            DataField = 'FOTEVEKENYSEG'
            DataSource = FEJSOURCE
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 8
          end
        end
        object KISUGYFELPANEL: TPanel
          Left = -1999
          Top = 40
          Width = 409
          Height = 113
          BevelOuter = bvNone
          TabOrder = 4
          Visible = False
          object Label32: TLabel
            Left = 16
            Top = 8
            Width = 266
            Height = 23
            Caption = 'KIS '#220'GYF'#201'L (300  ezer  alatt)'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object Label33: TLabel
            Left = 16
            Top = 56
            Width = 40
            Height = 16
            Caption = 'NEVE:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object Label34: TLabel
            Left = 14
            Top = 84
            Width = 72
            Height = 16
            Caption = 'SZ'#220'LET'#201'S:'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object DBEdit28: TDBEdit
            Left = 64
            Top = 50
            Width = 337
            Height = 24
            DataField = 'NEV'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object DBEdit29: TDBEdit
            Left = 88
            Top = 80
            Width = 73
            Height = 24
            DataField = 'SZULETESIIDO'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 1
          end
          object DBEdit30: TDBEdit
            Left = 164
            Top = 80
            Width = 237
            Height = 24
            DataField = 'SZULETESIHELY'
            DataSource = FEJSOURCE
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
          end
        end
      end
      object AKTINDEXEDIT: TEdit
        Left = 112
        Top = 416
        Width = 425
        Height = 26
        BorderStyle = bsNone
        Color = 16311512
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 2
      end
      object CONDINFOEDIT: TEdit
        Left = 112
        Top = 444
        Width = 425
        Height = 26
        BorderStyle = bsNone
        Color = 16311512
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object Panel5: TPanel
        Left = 552
        Top = 8
        Width = 57
        Height = 25
        Caption = 'DNEM'
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 4
      end
      object Panel6: TPanel
        Left = 616
        Top = 8
        Width = 73
        Height = 25
        Caption = 'BANKJEGY'
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 5
      end
      object Panel7: TPanel
        Left = 784
        Top = 8
        Width = 89
        Height = 25
        Caption = #201'RT'#201'K'
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 6
      end
      object Panel8: TPanel
        Left = 880
        Top = 8
        Width = 97
        Height = 25
        Caption = 'ELSZ-I '#193'RF'
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 7
      end
      object Panel9: TPanel
        Left = 696
        Top = 8
        Width = 81
        Height = 25
        Caption = #193'RFOLYAM'
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 8
      end
      object DBEdit22: TDBEdit
        Left = 564
        Top = 36
        Width = 33
        Height = 24
        DataField = 'VALUTANEM'
        DataSource = FEJSOURCE
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 9
      end
      object DBEdit23: TDBEdit
        Left = 616
        Top = 36
        Width = 73
        Height = 24
        DataField = 'BANKJEGY'
        DataSource = FEJSOURCE
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 10
      end
      object DBEdit24: TDBEdit
        Left = 712
        Top = 36
        Width = 49
        Height = 24
        DataField = 'ARFOLYAM'
        DataSource = FEJSOURCE
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 11
      end
      object DBEdit25: TDBEdit
        Left = 784
        Top = 36
        Width = 89
        Height = 24
        DataField = 'FTERTEK'
        DataSource = FEJSOURCE
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 12
      end
      object DBEdit26: TDBEdit
        Left = 896
        Top = 36
        Width = 57
        Height = 24
        DataField = 'ELSZAMARF'
        DataSource = FEJSOURCE
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 13
      end
    end
    object FELTETELPANEL: TPanel
      Left = 8
      Top = 82
      Width = 965
      Height = 455
      Color = clYellow
      TabOrder = 2
      Visible = False
      object Label30: TLabel
        Left = 24
        Top = 416
        Width = 80
        Height = 18
        Caption = 'SORREND:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label22: TLabel
        Left = 632
        Top = 416
        Width = 64
        Height = 18
        Caption = 'SZ'#368'R'#201'S:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object SZUROPANEL: TPanel
        Left = 416
        Top = 8
        Width = 537
        Height = 385
        TabOrder = 0
        object Label23: TLabel
          Left = 96
          Top = 45
          Width = 342
          Height = 21
          Caption = 'Melyik adat(ok) szerint sz'#252'rj'#252'k az adatokat ?'
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object FELTETELLISTA: TListBox
          Left = 16
          Top = 80
          Width = 241
          Height = 273
          Cursor = crHandPoint
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          ItemHeight = 15
          Items.Strings = (
            'Bizonylatsz'#225'm kezd'#337'bet'#252'je ...'
            'Bizonylat d'#225'tum sz'#252'r'#233'se ...'
            'Bizonylat kiad'#225'si idej'#233'nek sz'#252'r'#233'se ...'
            'A bizonylat forint'#246'sszeg'#233'nek sz'#252'r'#233'se ...'
            'Bizonylat kezel'#233'si k'#246'lts'#233'g sz'#252'r'#233'se ...'
            'P'#233'nzt'#225'rsz'#225'm szerinti sz'#252'r'#233's ...'
            'Valutanemek szerinti sz'#252'r'#233's ...'
            #220'gyfelek neveinek sz'#252'r'#233'se ...'
            #220'gyfelek anyja neveinek sz'#252'r'#233'se ...'
            #220'gyfelek sz'#252'let'#233'si idej'#233'nek sz'#252'r'#233'se ...'
            #220'gyfelek sz'#252'let'#233'si hely'#233'nek sz'#252'r'#233'se ...'
            #220'gyfelek lakcimeinek sz'#252'r'#233'se ...'
            #220'gyfelek utols'#243' v'#225'lt'#225's'#225'nak sz'#252'r'#233'se'
            #201'vi maxim'#225'lis v'#225'lt'#225'sok sz'#252'r'#233'se ...'
            #201'vi '#246'sszes v'#225'lt'#225'sok sz'#252'r'#233'se ...'
            'P'#233'nzt'#225'rosok neveinek sz'#252'r'#233'se ...'
            #220'gyf'#233'l tipusa szerinti sz'#252'r'#233'se ...')
          ParentFont = False
          TabOrder = 0
          Visible = False
          OnDblClick = FELTETELLISTADblClick
        end
        object BIZFELTETPANEL: TPanel
          Left = -500
          Top = 136
          Width = 249
          Height = 105
          Caption = ' '
          Color = clWhite
          TabOrder = 1
          Visible = False
          object Label24: TLabel
            Left = 16
            Top = 8
            Width = 227
            Height = 16
            Caption = 'BIZONYLATSZAM KEZD'#336'BET'#220'JE ?'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object BIZRENDBENGOMB: TBitBtn
            Left = 16
            Top = 72
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'RENDBEN'
            TabOrder = 0
            OnClick = BIZRENDBENGOMBClick
          end
          object BIZMEGSEMGOMB: TBitBtn
            Left = 136
            Top = 72
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'M'#201'GSEM'
            TabOrder = 1
            OnClick = BIZMEGSEMGOMBClick
          end
          object VBETURADIO: TRadioButton
            Left = 40
            Top = 40
            Width = 81
            Height = 17
            Caption = 'V - bet'#369
            Checked = True
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 2
            TabStop = True
            OnClick = VBETURADIOClick
          end
          object EBETURADIO: TRadioButton
            Left = 136
            Top = 40
            Width = 81
            Height = 17
            Caption = 'E - bet'#369
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 3
            OnClick = VBETURADIOClick
          end
        end
        object IDOFELTETPANEL: TPanel
          Left = -1999
          Top = 88
          Width = 257
          Height = 153
          Color = clWhite
          TabOrder = 2
          Visible = False
          object Label26: TLabel
            Left = 48
            Top = 32
            Width = 182
            Height = 17
            Caption = 'a lenti d'#225'tumhoz k'#233'pest ...'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object IDOBEFORERADIO: TRadioButton
            Left = 16
            Top = 56
            Width = 49
            Height = 17
            Caption = 'el'#246'tte'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 0
            OnClick = IDOAMONGRADIOClick
          end
          object IDOAFTERRADIO: TRadioButton
            Left = 72
            Top = 56
            Width = 49
            Height = 17
            Caption = 'ut'#225'na'
            Checked = True
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            TabStop = True
            OnClick = IDOAMONGRADIOClick
          end
          object IDOAMONGRADIO: TRadioButton
            Left = 128
            Top = 56
            Width = 65
            Height = 17
            Caption = 'k'#246'z'#246'tte'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            OnClick = IDOAMONGRADIOClick
          end
          object IDOKONKRETRADIO: TRadioButton
            Left = 192
            Top = 56
            Width = 57
            Height = 17
            Caption = 'akkor'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = IDOAMONGRADIOClick
          end
          object FIRSTDATEEDIT: TEdit
            Left = 32
            Top = 80
            Width = 89
            Height = 25
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            MaxLength = 10
            ParentFont = False
            TabOrder = 4
            Text = '2022.12.21'
            OnEnter = FIRSTDATEEDITEnter
            OnExit = FIRSTDATEEDITExit
            OnKeyDown = FIRSTDATEEDITKeyDown
          end
          object IGDATEEDIT: TEdit
            Left = 136
            Top = 80
            Width = 89
            Height = 25
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            MaxLength = 10
            ParentFont = False
            TabOrder = 5
            Text = '2022.06.14'
            OnEnter = FIRSTDATEEDITEnter
            OnExit = FIRSTDATEEDITExit
            OnKeyDown = IGDATEEDITKeyDown
          end
          object IDOCIMPANEL: TPanel
            Left = 8
            Top = 8
            Width = 241
            Height = 21
            BevelOuter = bvNone
            Caption = 'A SZ'#220'LET'#201'SI ID'#336
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 6
          end
          object IDORENDBENGOMB: TBitBtn
            Left = 24
            Top = 120
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'RENDBEN'
            TabOrder = 7
            OnClick = IDORENDBENGOMBClick
          end
          object IDOMEGSEMGOMB: TBitBtn
            Left = 128
            Top = 120
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'M'#201'GSEM'
            TabOrder = 8
            OnClick = IDOMEGSEMGOMBClick
          end
        end
        object NUMFELTETPANEL: TPanel
          Left = -500
          Top = 80
          Width = 250
          Height = 145
          Color = clWhite
          TabOrder = 3
          Visible = False
          object Label25: TLabel
            Left = 32
            Top = 35
            Width = 185
            Height = 17
            Caption = 'a lenti '#246'sszeghez k'#233'pest ...'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
          end
          object NUMCIMPANEL: TPanel
            Left = 8
            Top = 8
            Width = 241
            Height = 21
            BevelOuter = bvNone
            Caption = 'A KEZEL'#201'SI D'#205'J'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object NUMLESSRADIO: TRadioButton
            Left = 4
            Top = 60
            Width = 58
            Height = 17
            Caption = 'kisebb'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = NUMBETWEENRADIOClick
          end
          object NUMBIGGERRADIO: TRadioButton
            Left = 68
            Top = 60
            Width = 68
            Height = 17
            Caption = 'nagyobb'
            Checked = True
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            TabStop = True
            OnClick = NUMBETWEENRADIOClick
          end
          object NUMBETWEENRADIO: TRadioButton
            Left = 140
            Top = 60
            Width = 56
            Height = 17
            Caption = 'k'#246'z'#246'tt'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = NUMBETWEENRADIOClick
          end
          object NUMKONKRETRADIO: TRadioButton
            Left = 200
            Top = 60
            Width = 50
            Height = 17
            Caption = 'annyi'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 4
            OnClick = NUMBETWEENRADIOClick
          end
          object FIRSTNUMEDIT: TEdit
            Left = 32
            Top = 88
            Width = 89
            Height = 26
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            MaxLength = 9
            ParentFont = False
            TabOrder = 5
            Text = '254500400'
            OnEnter = FIRSTDATEEDITEnter
            OnExit = FIRSTDATEEDITExit
            OnKeyDown = FIRSTNUMEDITKeyDown
          end
          object IGNUMEDIT: TEdit
            Left = 128
            Top = 88
            Width = 89
            Height = 26
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold]
            MaxLength = 9
            ParentFont = False
            TabOrder = 6
            Text = '250489600'
            OnEnter = FIRSTDATEEDITEnter
            OnExit = FIRSTDATEEDITExit
            OnKeyDown = IGNUMEDITKeyDown
          end
          object NUMOKEGOMB: TBitBtn
            Left = 24
            Top = 120
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'RENDBEN'
            TabOrder = 7
            OnClick = NUMOKEGOMBClick
          end
          object NUMMEGSEMGOMB: TBitBtn
            Left = 128
            Top = 120
            Width = 75
            Height = 18
            Cursor = crHandPoint
            Caption = 'M'#201'GSEM'
            TabOrder = 8
            OnClick = NUMMEGSEMGOMBClick
          end
        end
        object NEVFELTETPANEL: TPanel
          Left = -500
          Top = 64
          Width = 257
          Height = 129
          Color = clWhite
          TabOrder = 4
          Visible = False
          object Label27: TLabel
            Left = 88
            Top = 40
            Width = 87
            Height = 23
            Caption = 'kezdete ....'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -21
            Font.Name = 'Times New Roman'
            Font.Style = [fsItalic]
            ParentFont = False
          end
          object NEVCIMPANEL: TPanel
            Left = 8
            Top = 8
            Width = 233
            Height = 21
            Caption = 'ANYJA NEVE'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object NEVKEZDETEDIT: TEdit
            Left = 32
            Top = 72
            Width = 185
            Height = 21
            CharCase = ecUpperCase
            TabOrder = 1
            Text = 'NEVKEZDETEDIT'
            OnEnter = FIRSTDATEEDITEnter
            OnExit = FIRSTDATEEDITExit
            OnKeyPress = NEVKEZDETEDITKeyPress
          end
          object NEVOKEGOMB: TBitBtn
            Left = 24
            Top = 104
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'RENDBEN'
            TabOrder = 2
            OnClick = NEVOKEGOMBClick
          end
          object NEVMEGSEMGOMB: TBitBtn
            Left = 144
            Top = 104
            Width = 99
            Height = 18
            Cursor = crHandPoint
            Caption = 'M'#201'GSEM'
            TabOrder = 3
            OnClick = NEVMEGSEMGOMBClick
          end
        end
        object SZUROPANELGOMB: TPanel
          Left = 8
          Top = 8
          Width = 521
          Height = 25
          Cursor = crHandPoint
          Caption = 'ADATOK SZ'#220'R'#201'S'#201'NEK BE'#193'LL'#205'T'#193'SA'
          Color = clWhite
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
          TabOrder = 5
          OnClick = SZUROPANELGOMBClick
        end
        object TIPUSFELTETPANEL: TPanel
          Left = -585
          Top = 80
          Width = 245
          Height = 233
          Color = clWhite
          TabOrder = 6
          Visible = False
          object Panel4: TPanel
            Left = 0
            Top = 8
            Width = 241
            Height = 21
            BevelOuter = bvNone
            Caption = #220'GYF'#201'L TIPUSA'
            Font.Charset = ANSI_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Arial'
            Font.Style = [fsBold, fsItalic]
            ParentFont = False
            TabOrder = 0
          end
          object ALLUGYFELRADIO: TRadioButton
            Left = 32
            Top = 64
            Width = 113
            Height = 17
            Caption = 'MINDEN '#220'GYFEL'
            TabOrder = 1
          end
          object CSAKJOGIRADIO: TRadioButton
            Left = 32
            Top = 136
            Width = 153
            Height = 17
            Caption = 'CSAK JOGI SZEM'#201'LYEK'
            TabOrder = 2
          end
          object CSAKNATURRADIO: TRadioButton
            Left = 32
            Top = 112
            Width = 201
            Height = 17
            Caption = 'CSAK TERM'#201'SZETES SZEM'#201'LYEK'
            TabOrder = 3
          end
          object TIPUSRENDBENGOMB: TBitBtn
            Left = 24
            Top = 200
            Width = 97
            Height = 18
            Cursor = crHandPoint
            Caption = 'RENDBEN'
            TabOrder = 4
            OnClick = TIPUSRENDBENGOMBClick
          end
          object TIPUSMEGSEMGOMB: TBitBtn
            Left = 128
            Top = 200
            Width = 97
            Height = 18
            Cursor = crHandPoint
            Caption = 'M'#201'GSEM'
            TabOrder = 5
            OnClick = TIPUSMEGSEMGOMBClick
          end
          object RadioButton1: TRadioButton
            Left = 32
            Top = 160
            Width = 161
            Height = 17
            Caption = 'CSAK A KIS'#220'GYFELEK'
            TabOrder = 6
          end
          object KISUGYFELNELKULRADIO: TRadioButton
            Left = 32
            Top = 88
            Width = 209
            Height = 17
            Caption = 'KIS'#220'GYFELEK N'#201'LK'#220'L MINDENKI'
            Checked = True
            TabOrder = 7
            TabStop = True
          end
        end
      end
      object SORRENDPANEL: TPanel
        Left = 8
        Top = 8
        Width = 400
        Height = 385
        TabOrder = 1
        object Label28: TLabel
          Left = 30
          Top = 48
          Width = 357
          Height = 21
          Caption = 'Melyik adat sorrendj'#233'ben legyenek az adatok ?'
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          ParentFont = False
        end
        object SORRENDGOMB: TPanel
          Left = 8
          Top = 8
          Width = 385
          Height = 25
          Cursor = crHandPoint
          Caption = 'ADATOK SORRENDJ'#201'NEK MEGHAT'#193'ROZ'#193'SA'
          Color = clWhite
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
          TabOrder = 0
          OnClick = SORRENDGOMBClick
        end
        object INDEXLISTA: TListBox
          Left = 12
          Top = 80
          Width = 369
          Height = 272
          Cursor = crHandPoint
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsItalic]
          ItemHeight = 19
          Items.Strings = (
            'Bizonylatsz'#225'mok sorrendj'#233'ben ...'
            'Bizonylatok d'#225'tuma szerint ....'
            'Bizonylatok kiad'#225'si ideje szerint ...'
            'Kifizetett/bevett forint'#246'sszegek szerint'
            'Tranzakci'#243'k kezel'#233'si d'#237'jai szerint ...'
            'P'#233'nzt'#225'rsz'#225'mok sorrendj'#233'ben ...'
            'Valutanemek sorrendj'#233'ben ...'
            #220'gyfelek nevei szerint ....'
            #220'gyfelek anyja nevei szerint  ...'
            #220'gyfelek sz'#252'let'#233'si ideje sorrendj'#233'ben  ...'
            #220'gyfelek sz'#252'let'#233'si hely'#233'nek sorrendj'#233'ben ...'
            #220'gyfelek lakcimeinek sorrendj'#233'ben ...'
            'Az '#233'vi maxim'#225'lis emelked'#337' sorrendj'#233'ben'
            'Az '#233'vi '#246'sszes v'#225'lt'#225's sorrendj'#233'ben ...'
            'P'#233'nzt'#225'rosok n'#233'vsora szerint')
          ParentFont = False
          TabOrder = 1
          Visible = False
          OnDblClick = INDEXLISTADblClick
        end
      end
      object SZURESRENDBENGOMB: TBitBtn
        Left = 328
        Top = 408
        Width = 129
        Height = 25
        Cursor = crHandPoint
        Caption = 'RENDBEN'
        TabOrder = 2
        OnClick = SZURESRENDBENGOMBClick
      end
      object SZURESMEGSEMGOMB: TBitBtn
        Left = 472
        Top = 408
        Width = 137
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        TabOrder = 3
        OnClick = SZURESMEGSEMGOMBClick
      end
      object SORRENDEDIT: TEdit
        Left = 112
        Top = 416
        Width = 185
        Height = 26
        BorderStyle = bsNone
        Color = clYellow
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object INFOPANEL: TPanel
        Left = 346
        Top = 365
        Width = 185
        Height = 22
        BevelOuter = bvNone
        Caption = 'V'#225'laszt'#225's -> dupla klikk'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 5
        Visible = False
      end
      object FELTETEDIT: TEdit
        Left = 704
        Top = 416
        Width = 249
        Height = 26
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = clYellow
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 6
      end
    end
  end
  object BIZLATOKQUERY: TIBQuery
    Database = BIZLATOKDBASE
    Transaction = BIZLATOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 880
    Top = 440
  end
  object BIZLATOKDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZLATOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 912
    Top = 440
  end
  object BIZLATOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZLATOKDBASE
    AutoStopAction = saNone
    Left = 936
    Top = 440
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'select * from adatgyujto'
      '')
    Left = 40
    Top = 88
    object FEJQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'ADATGYUJTO.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'ADATGYUJTO.DATUM'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'ADATGYUJTO.IDO'
      FixedChar = True
      Size = 8
    end
    object FEJQUERYFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
      Origin = 'ADATGYUJTO.FIZETENDO'
      DisplayFormat = '### ### ### Ft'
    end
    object FEJQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'ADATGYUJTO.KEZELESIDIJ'
      DisplayFormat = '# ### Ft'
    end
    object FEJQUERYPENZTARSZAM: TSmallintField
      FieldName = 'PENZTARSZAM'
      Origin = 'ADATGYUJTO.PENZTARSZAM'
    end
    object FEJQUERYPENZTARNEV: TIBStringField
      FieldName = 'PENZTARNEV'
      Origin = 'ADATGYUJTO.PENZTARNEV'
      FixedChar = True
      Size = 30
    end
    object FEJQUERYSORSZAM: TIntegerField
      FieldName = 'SORSZAM'
      Origin = 'ADATGYUJTO.SORSZAM'
    end
    object FEJQUERYPROSID: TIBStringField
      FieldName = 'PROSID'
      Origin = 'ADATGYUJTO.PROSID'
      FixedChar = True
      Size = 5
    end
    object FEJQUERYNEVTABLA: TIBStringField
      FieldName = 'NEVTABLA'
      Origin = 'ADATGYUJTO.NEVTABLA'
      FixedChar = True
      Size = 4
    end
    object FEJQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'ADATGYUJTO.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object FEJQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'ADATGYUJTO.BANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object FEJQUERYARFOLYAM: TIntegerField
      FieldName = 'ARFOLYAM'
      Origin = 'ADATGYUJTO.ARFOLYAM'
      DisplayFormat = '### ##'
    end
    object FEJQUERYELSZAMARF: TIntegerField
      FieldName = 'ELSZAMARF'
      Origin = 'ADATGYUJTO.ELSZAMARF'
      DisplayFormat = '### ##'
    end
    object FEJQUERYFTERTEK: TIntegerField
      FieldName = 'FTERTEK'
      Origin = 'ADATGYUJTO.FTERTEK'
      DisplayFormat = '### ### ### Ft'
    end
    object FEJQUERYNEV: TIBStringField
      FieldName = 'NEV'
      Origin = 'ADATGYUJTO.NEV'
      FixedChar = True
      Size = 50
    end
    object FEJQUERYANYJANEVE: TIBStringField
      FieldName = 'ANYJANEVE'
      Origin = 'ADATGYUJTO.ANYJANEVE'
      FixedChar = True
      Size = 50
    end
    object FEJQUERYSZULETESIIDO: TIBStringField
      FieldName = 'SZULETESIIDO'
      Origin = 'ADATGYUJTO.SZULETESIIDO'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYSZULETESIHELY: TIBStringField
      FieldName = 'SZULETESIHELY'
      Origin = 'ADATGYUJTO.SZULETESIHELY'
      FixedChar = True
      Size = 40
    end
    object FEJQUERYLAKCIM: TIBStringField
      FieldName = 'LAKCIM'
      Origin = 'ADATGYUJTO.LAKCIM'
      FixedChar = True
      Size = 60
    end
    object FEJQUERYUTOLSOVALTAS: TIBStringField
      FieldName = 'UTOLSOVALTAS'
      Origin = 'ADATGYUJTO.UTOLSOVALTAS'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYEVIMAX: TIntegerField
      FieldName = 'EVIMAX'
      Origin = 'ADATGYUJTO.EVIMAX'
      DisplayFormat = '### ### ### Ft'
    end
    object FEJQUERYVALTASDB: TSmallintField
      FieldName = 'VALTASDB'
      Origin = 'ADATGYUJTO.VALTASDB'
      DisplayFormat = '### db'
    end
    object FEJQUERYOSSZESVALTAS: TIntegerField
      FieldName = 'OSSZESVALTAS'
      Origin = 'ADATGYUJTO.OSSZESVALTAS'
      DisplayFormat = '### ### ### Ft'
    end
    object FEJQUERYKORZET: TSmallintField
      FieldName = 'KORZET'
      Origin = 'ADATGYUJTO.KORZET'
    end
    object FEJQUERYKFT: TIBStringField
      FieldName = 'KFT'
      Origin = 'ADATGYUJTO.KFT'
      FixedChar = True
      Size = 1
    end
    object FEJQUERYKEPVISNEV: TIBStringField
      FieldName = 'KEPVISNEV'
      Origin = 'ADATGYUJTO.KEPVISNEV'
      FixedChar = True
      Size = 40
    end
    object FEJQUERYMBBEO: TIBStringField
      FieldName = 'MBBEO'
      Origin = 'ADATGYUJTO.MBBEO'
      FixedChar = True
      Size = 30
    end
    object FEJQUERYKEPVISBEO: TIBStringField
      FieldName = 'KEPVISBEO'
      Origin = 'ADATGYUJTO.KEPVISBEO'
      FixedChar = True
      Size = 30
    end
    object FEJQUERYMEGBIZOTTNEVE: TIBStringField
      FieldName = 'MEGBIZOTTNEVE'
      Origin = 'ADATGYUJTO.MEGBIZOTTNEVE'
      FixedChar = True
      Size = 35
    end
    object FEJQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'ADATGYUJTO.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object FEJQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'ADATGYUJTO.PENZTAROSNEV'
      FixedChar = True
      Size = 35
    end
    object FEJQUERYISO: TIBStringField
      FieldName = 'ISO'
      Origin = 'ADATGYUJTO.ISO'
      FixedChar = True
      Size = 2
    end
    object FEJQUERYMARKER: TSmallintField
      FieldName = 'MARKER'
      Origin = 'ADATGYUJTO.MARKER'
    end
    object FEJQUERYCEGNEV: TIBStringField
      FieldName = 'CEGNEV'
      Origin = 'ADATGYUJTO.CEGNEV'
      FixedChar = True
      Size = 50
    end
    object FEJQUERYOKIRATSZAM: TIBStringField
      FieldName = 'OKIRATSZAM'
      Origin = 'ADATGYUJTO.OKIRATSZAM'
      FixedChar = True
      Size = 25
    end
    object FEJQUERYMBSZULIDO: TIBStringField
      FieldName = 'MBSZULIDO'
      Origin = 'ADATGYUJTO.MBSZULIDO'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYMBSZULHELY: TIBStringField
      FieldName = 'MBSZULHELY'
      Origin = 'ADATGYUJTO.MBSZULHELY'
      FixedChar = True
      Size = 40
    end
    object FEJQUERYMBANYJA: TIBStringField
      FieldName = 'MBANYJA'
      Origin = 'ADATGYUJTO.MBANYJA'
      FixedChar = True
      Size = 30
    end
    object FEJQUERYTELEPHELYCIM: TIBStringField
      FieldName = 'TELEPHELYCIM'
      Origin = 'ADATGYUJTO.TELEPHELYCIM'
      FixedChar = True
      Size = 60
    end
    object FEJQUERYALLAMPOLGAR: TIBStringField
      FieldName = 'ALLAMPOLGAR'
      Origin = 'ADATGYUJTO.ALLAMPOLGAR'
      FixedChar = True
    end
    object FEJQUERYMBALLAMPOLGAR: TIBStringField
      FieldName = 'MBALLAMPOLGAR'
      Origin = 'ADATGYUJTO.MBALLAMPOLGAR'
      FixedChar = True
    end
    object FEJQUERYOKMANYTIPUS: TIBStringField
      FieldName = 'OKMANYTIPUS'
      Origin = 'ADATGYUJTO.OKMANYTIPUS'
      FixedChar = True
      Size = 15
    end
    object FEJQUERYAZONOSITO: TIBStringField
      FieldName = 'AZONOSITO'
      Origin = 'ADATGYUJTO.AZONOSITO'
      FixedChar = True
    end
    object FEJQUERYMBOKMTIPUS: TIBStringField
      FieldName = 'MBOKMTIPUS'
      Origin = 'ADATGYUJTO.MBOKMTIPUS'
      FixedChar = True
      Size = 15
    end
    object FEJQUERYMBAZONOSITO: TIBStringField
      FieldName = 'MBAZONOSITO'
      Origin = 'ADATGYUJTO.MBAZONOSITO'
      FixedChar = True
    end
    object FEJQUERYCEGORSZAG: TIBStringField
      FieldName = 'CEGORSZAG'
      Origin = 'ADATGYUJTO.CEGORSZAG'
      FixedChar = True
      Size = 30
    end
    object FEJQUERYPENZTARCIM: TIBStringField
      FieldName = 'PENZTARCIM'
      Origin = 'ADATGYUJTO.PENZTARCIM'
      FixedChar = True
      Size = 50
    end
    object FEJQUERYFOTEVEKENYSEG: TIBStringField
      FieldName = 'FOTEVEKENYSEG'
      Origin = 'ADATGYUJTO.FOTEVEKENYSEG'
      FixedChar = True
      Size = 40
    end
  end
  object FEJDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 88
  end
  object FEJTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 88
  end
  object FEJSOURCE: TDataSource
    DataSet = FEJQUERY
    Left = 152
    Top = 88
  end
end
