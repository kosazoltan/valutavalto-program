object Form2: TForm2
  Left = 201
  Top = 120
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 585
  ClientWidth = 857
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
  object ALAPLAP: TPanel
    Left = 16
    Top = 8
    Width = 857
    Height = 585
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 0
    object Label1: TLabel
      Left = 184
      Top = 24
      Width = 487
      Height = 27
      Caption = 'EGY HAVI HORV'#193'T KUNA FORGALOM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 32
      Top = 64
      Width = 66
      Height = 19
      Caption = 'P'#201'NZT'#193'R:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 584
      Top = 64
      Width = 55
      Height = 19
      Caption = 'K'#214'RZET:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 384
      Top = 62
      Width = 88
      Height = 19
      Caption = 'VALUTANEM:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object RACSPANEL: TPanel
      Left = 24
      Top = 96
      Width = 801
      Height = 433
      BevelOuter = bvNone
      Color = clCream
      TabOrder = 0
      Visible = False
      object Label5: TLabel
        Left = 320
        Top = 0
        Width = 174
        Height = 31
        Caption = '2023 febru'#225'r'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object HRKRACS: TDBGrid
        Left = -1789
        Top = 32
        Width = 801
        Height = 345
        DataSource = HRKSOURCE
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Visible = False
        OnCellClick = HRKRACSCellClick
        OnDblClick = HRKRACSDblClick
        OnKeyUp = HRKRACSKeyUp
        Columns = <
          item
            Expanded = False
            FieldName = 'V1'
            Title.Alignment = taCenter
            Title.Caption = '1.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V2'
            Title.Alignment = taCenter
            Title.Caption = '2.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V3'
            Title.Alignment = taCenter
            Title.Caption = '3.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V4'
            Title.Alignment = taCenter
            Title.Caption = '4.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V5'
            Title.Alignment = taCenter
            Title.Caption = '5.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V6'
            Title.Alignment = taCenter
            Title.Caption = '6.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V7'
            Title.Alignment = taCenter
            Title.Caption = '7.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V8'
            Title.Alignment = taCenter
            Title.Caption = '8.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V9'
            Title.Alignment = taCenter
            Title.Caption = '9.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V10'
            Title.Alignment = taCenter
            Title.Caption = '10.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V11'
            Title.Alignment = taCenter
            Title.Caption = '11.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V12'
            Title.Alignment = taCenter
            Title.Caption = '12.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V13'
            Title.Alignment = taCenter
            Title.Caption = '13.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V14'
            Title.Alignment = taCenter
            Title.Caption = '14.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V15'
            Title.Alignment = taCenter
            Title.Caption = '15.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V16'
            Title.Alignment = taCenter
            Title.Caption = '16.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V17'
            Title.Alignment = taCenter
            Title.Caption = '17.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V18'
            Title.Alignment = taCenter
            Title.Caption = '18.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V19'
            Title.Alignment = taCenter
            Title.Caption = '19.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V20'
            Title.Alignment = taCenter
            Title.Caption = '20.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V21'
            Title.Alignment = taCenter
            Title.Caption = '21.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V22'
            Title.Alignment = taCenter
            Title.Caption = '22.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V23'
            Title.Alignment = taCenter
            Title.Caption = '23.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V24'
            Title.Alignment = taCenter
            Title.Caption = '24.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V25'
            Title.Alignment = taCenter
            Title.Caption = '25.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V26'
            Title.Alignment = taCenter
            Title.Caption = '26.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V27'
            Title.Alignment = taCenter
            Title.Caption = '27.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V28'
            Title.Alignment = taCenter
            Title.Caption = '28.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V29'
            Title.Alignment = taCenter
            Title.Caption = '29.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V30'
            Title.Alignment = taCenter
            Title.Caption = '30.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'V31'
            Title.Alignment = taCenter
            Title.Caption = '31.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VSUM'
            Title.Alignment = taCenter
            Title.Caption = #214'SSZES'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end>
      end
      object PENZTARGOMB: TBitBtn
        Left = 32
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'P'#201'NZT'#193'RAK'
        TabOrder = 1
        OnClick = PENZTARGOMBClick
      end
      object KORZETGOMB: TBitBtn
        Left = 160
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'KORZETEK'
        TabOrder = 2
        OnClick = KORZETGOMBClick
      end
      object KILEPOGOMB: TBitBtn
        Left = 672
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'KIL'#201'P'#201'S'
        TabOrder = 3
        OnClick = KILEPOGOMBClick
      end
      object HRKHUFGOMB: TBitBtn
        Left = 544
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'HRK/HUF'
        TabOrder = 4
        OnClick = HRKHUFGOMBClick
      end
      object CHANGEGOMB: TBitBtn
        Left = 288
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXCLUSIVE CHANGE'
        TabOrder = 5
        OnClick = CHANGEGOMBClick
      end
      object EXCELGOMB: TBitBtn
        Left = 416
        Top = 400
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXCELT'#193'BLA'
        TabOrder = 6
        OnClick = EXCELGOMBClick
      end
      object HUFRACS: TDBGrid
        Left = -1478
        Top = 32
        Width = 801
        Height = 345
        DataSource = HUFSOURCE
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 7
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Visible = False
        OnCellClick = HRKRACSCellClick
        OnDblClick = HRKRACSDblClick
        OnKeyUp = HRKRACSKeyUp
        Columns = <
          item
            Expanded = False
            FieldName = 'E1'
            Title.Alignment = taCenter
            Title.Caption = '1.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E2'
            Title.Alignment = taCenter
            Title.Caption = '2.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E3'
            Title.Alignment = taCenter
            Title.Caption = '3.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E4'
            Title.Alignment = taCenter
            Title.Caption = '4.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E5'
            Title.Alignment = taCenter
            Title.Caption = '5.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E6'
            Title.Alignment = taCenter
            Title.Caption = '6.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E7'
            Title.Alignment = taCenter
            Title.Caption = '7.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E8'
            Title.Alignment = taCenter
            Title.Caption = '8.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E9'
            Title.Alignment = taCenter
            Title.Caption = '9.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E10'
            Title.Alignment = taCenter
            Title.Caption = '10.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E11'
            Title.Alignment = taCenter
            Title.Caption = '11.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E12'
            Title.Alignment = taCenter
            Title.Caption = '12.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E13'
            Title.Alignment = taCenter
            Title.Caption = '13.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E14'
            Title.Alignment = taCenter
            Title.Caption = '14.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E15'
            Title.Alignment = taCenter
            Title.Caption = '15.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E16'
            Title.Alignment = taCenter
            Title.Caption = '16.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E17'
            Title.Alignment = taCenter
            Title.Caption = '17.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E18'
            Title.Alignment = taCenter
            Title.Caption = '18.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E19'
            Title.Alignment = taCenter
            Title.Caption = '19.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E20'
            Title.Alignment = taCenter
            Title.Caption = '20.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E21'
            Title.Alignment = taCenter
            Title.Caption = '21.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E22'
            Title.Alignment = taCenter
            Title.Caption = '22.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E23'
            Title.Alignment = taCenter
            Title.Caption = '23.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E24'
            Title.Alignment = taCenter
            Title.Caption = '24.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E25'
            Title.Alignment = taCenter
            Title.Caption = '25.'
            Title.Font.Charset = ANSI_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E26'
            Title.Alignment = taCenter
            Title.Caption = '26.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E27'
            Title.Alignment = taCenter
            Title.Caption = '27.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E28'
            Title.Alignment = taCenter
            Title.Caption = '28.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E29'
            Title.Alignment = taCenter
            Title.Caption = '29.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E30'
            Title.Alignment = taCenter
            Title.Caption = '30.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'E31'
            Title.Alignment = taCenter
            Title.Caption = '31.'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ESUM'
            Title.Alignment = taCenter
            Title.Caption = #214'SSZES'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -13
            Title.Font.Name = 'Calibri'
            Title.Font.Style = [fsBold]
            Visible = True
          end>
      end
      object GOMBTAKARO: TPanel
        Left = 24
        Top = 386
        Width = 641
        Height = 41
        BevelOuter = bvNone
        Color = clCream
        TabOrder = 8
        Visible = False
      end
    end
    object CSIK: TProgressBar
      Left = 32
      Top = 544
      Width = 801
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 1
    end
    object PENZTARNEVEDIT: TEdit
      Left = 104
      Top = 62
      Width = 265
      Height = 27
      BorderStyle = bsNone
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      ReadOnly = True
      TabOrder = 2
    end
    object KORZETNEVEDIT: TEdit
      Left = 648
      Top = 62
      Width = 177
      Height = 27
      BorderStyle = bsNone
      Color = clGray
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object DNEMPANEL: TPanel
      Left = 480
      Top = 60
      Width = 41
      Height = 25
      BevelOuter = bvNone
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTimer
    Left = 32
    Top = 16
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 16
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 16
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 16
  end
  object DAYBQUERY: TIBQuery
    Database = DAYBDBASE
    Transaction = DAYBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 72
  end
  object DAYBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = DAYBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 72
  end
  object DAYBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 72
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 296
    Top = 72
    object HRKQUERYPENZTARSZAM: TSmallintField
      FieldName = 'PENZTARSZAM'
      Origin = 'HRK2302.PENZTARSZAM'
    end
    object HRKQUERYPENZTARKOD: TIBStringField
      FieldName = 'PENZTARKOD'
      Origin = 'HRK2302.PENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object HRKQUERYPENZTARNEV: TIBStringField
      FieldName = 'PENZTARNEV'
      Origin = 'HRK2302.PENZTARNEV'
      FixedChar = True
      Size = 30
    end
    object HRKQUERYV1: TIntegerField
      FieldName = 'V1'
      Origin = 'HRK2302.V1'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE1: TIntegerField
      FieldName = 'E1'
      Origin = 'HRK2302.E1'
    end
    object HRKQUERYV2: TIntegerField
      FieldName = 'V2'
      Origin = 'HRK2302.V2'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE2: TIntegerField
      FieldName = 'E2'
      Origin = 'HRK2302.E2'
    end
    object HRKQUERYV3: TIntegerField
      FieldName = 'V3'
      Origin = 'HRK2302.V3'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE3: TIntegerField
      FieldName = 'E3'
      Origin = 'HRK2302.E3'
    end
    object HRKQUERYV4: TIntegerField
      FieldName = 'V4'
      Origin = 'HRK2302.V4'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE4: TIntegerField
      FieldName = 'E4'
      Origin = 'HRK2302.E4'
    end
    object HRKQUERYV5: TIntegerField
      FieldName = 'V5'
      Origin = 'HRK2302.V5'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE5: TIntegerField
      FieldName = 'E5'
      Origin = 'HRK2302.E5'
    end
    object HRKQUERYV6: TIntegerField
      FieldName = 'V6'
      Origin = 'HRK2302.V6'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE6: TIntegerField
      FieldName = 'E6'
      Origin = 'HRK2302.E6'
    end
    object HRKQUERYV7: TIntegerField
      FieldName = 'V7'
      Origin = 'HRK2302.V7'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE7: TIntegerField
      FieldName = 'E7'
      Origin = 'HRK2302.E7'
    end
    object HRKQUERYV8: TIntegerField
      FieldName = 'V8'
      Origin = 'HRK2302.V8'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE8: TIntegerField
      FieldName = 'E8'
      Origin = 'HRK2302.E8'
    end
    object HRKQUERYV9: TIntegerField
      FieldName = 'V9'
      Origin = 'HRK2302.V9'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE9: TIntegerField
      FieldName = 'E9'
      Origin = 'HRK2302.E9'
    end
    object HRKQUERYV10: TIntegerField
      FieldName = 'V10'
      Origin = 'HRK2302.V10'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE10: TIntegerField
      FieldName = 'E10'
      Origin = 'HRK2302.E10'
    end
    object HRKQUERYV11: TIntegerField
      FieldName = 'V11'
      Origin = 'HRK2302.V11'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE11: TIntegerField
      FieldName = 'E11'
      Origin = 'HRK2302.E11'
    end
    object HRKQUERYV12: TIntegerField
      FieldName = 'V12'
      Origin = 'HRK2302.V12'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE12: TIntegerField
      FieldName = 'E12'
      Origin = 'HRK2302.E12'
    end
    object HRKQUERYV13: TIntegerField
      FieldName = 'V13'
      Origin = 'HRK2302.V13'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE13: TIntegerField
      FieldName = 'E13'
      Origin = 'HRK2302.E13'
    end
    object HRKQUERYV14: TIntegerField
      FieldName = 'V14'
      Origin = 'HRK2302.V14'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE14: TIntegerField
      FieldName = 'E14'
      Origin = 'HRK2302.E14'
    end
    object HRKQUERYV15: TIntegerField
      FieldName = 'V15'
      Origin = 'HRK2302.V15'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE15: TIntegerField
      FieldName = 'E15'
      Origin = 'HRK2302.E15'
    end
    object HRKQUERYV16: TIntegerField
      FieldName = 'V16'
      Origin = 'HRK2302.V16'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE16: TIntegerField
      FieldName = 'E16'
      Origin = 'HRK2302.E16'
    end
    object HRKQUERYV17: TIntegerField
      FieldName = 'V17'
      Origin = 'HRK2302.V17'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE17: TIntegerField
      FieldName = 'E17'
      Origin = 'HRK2302.E17'
    end
    object HRKQUERYV18: TIntegerField
      FieldName = 'V18'
      Origin = 'HRK2302.V18'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE18: TIntegerField
      FieldName = 'E18'
      Origin = 'HRK2302.E18'
    end
    object HRKQUERYV19: TIntegerField
      FieldName = 'V19'
      Origin = 'HRK2302.V19'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE19: TIntegerField
      FieldName = 'E19'
      Origin = 'HRK2302.E19'
    end
    object HRKQUERYV20: TIntegerField
      FieldName = 'V20'
      Origin = 'HRK2302.V20'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE20: TIntegerField
      FieldName = 'E20'
      Origin = 'HRK2302.E20'
    end
    object HRKQUERYV21: TIntegerField
      FieldName = 'V21'
      Origin = 'HRK2302.V21'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE21: TIntegerField
      FieldName = 'E21'
      Origin = 'HRK2302.E21'
    end
    object HRKQUERYV22: TIntegerField
      FieldName = 'V22'
      Origin = 'HRK2302.V22'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE22: TIntegerField
      FieldName = 'E22'
      Origin = 'HRK2302.E22'
    end
    object HRKQUERYV23: TIntegerField
      FieldName = 'V23'
      Origin = 'HRK2302.V23'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE23: TIntegerField
      FieldName = 'E23'
      Origin = 'HRK2302.E23'
    end
    object HRKQUERYV24: TIntegerField
      FieldName = 'V24'
      Origin = 'HRK2302.V24'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE24: TIntegerField
      FieldName = 'E24'
      Origin = 'HRK2302.E24'
    end
    object HRKQUERYV25: TIntegerField
      FieldName = 'V25'
      Origin = 'HRK2302.V25'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE25: TIntegerField
      FieldName = 'E25'
      Origin = 'HRK2302.E25'
    end
    object HRKQUERYV26: TIntegerField
      FieldName = 'V26'
      Origin = 'HRK2302.V26'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE26: TIntegerField
      FieldName = 'E26'
      Origin = 'HRK2302.E26'
    end
    object HRKQUERYV27: TIntegerField
      FieldName = 'V27'
      Origin = 'HRK2302.V27'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE27: TIntegerField
      FieldName = 'E27'
      Origin = 'HRK2302.E27'
    end
    object HRKQUERYV28: TIntegerField
      FieldName = 'V28'
      Origin = 'HRK2302.V28'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE28: TIntegerField
      FieldName = 'E28'
      Origin = 'HRK2302.E28'
    end
    object HRKQUERYV29: TIntegerField
      FieldName = 'V29'
      Origin = 'HRK2302.V29'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE29: TIntegerField
      FieldName = 'E29'
      Origin = 'HRK2302.E29'
    end
    object HRKQUERYV30: TIntegerField
      FieldName = 'V30'
      Origin = 'HRK2302.V30'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE30: TIntegerField
      FieldName = 'E30'
      Origin = 'HRK2302.E30'
    end
    object HRKQUERYV31: TIntegerField
      FieldName = 'V31'
      Origin = 'HRK2302.V31'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYE31: TIntegerField
      FieldName = 'E31'
      Origin = 'HRK2302.E31'
    end
    object HRKQUERYVSUM: TIntegerField
      FieldName = 'VSUM'
      Origin = 'HRK2302.VSUM'
      DisplayFormat = '### ### ###'
    end
    object HRKQUERYESUM: TIntegerField
      FieldName = 'ESUM'
      Origin = 'HRK2302.ESUM'
    end
    object HRKQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'HRK2302.ERTEKTAR'
    end
    object HRKQUERYKORZETNEV: TIBStringField
      FieldName = 'KORZETNEV'
      Origin = 'HRK2302.KORZETNEV'
      FixedChar = True
      Size = 15
    end
  end
  object HRKDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\HRKSERVER.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 328
    Top = 72
  end
  object HRKTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = HRKDBASE
    AutoStopAction = saNone
    Left = 360
    Top = 72
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 728
    Top = 112
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V10.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 760
    Top = 112
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 792
    Top = 112
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 696
    Top = 112
  end
  object HRKSOURCE: TDataSource
    DataSet = HRKQUERY
    Enabled = False
    Left = 496
    Top = 72
  end
  object HUFSOURCE: TDataSource
    DataSet = HUFQUERY
    Enabled = False
    Left = 528
    Top = 72
  end
  object HUFQUERY: TIBQuery
    Database = HUFDBASE
    Transaction = HUFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 664
    Top = 72
    object HUFQUERYPENZTARSZAM: TSmallintField
      FieldName = 'PENZTARSZAM'
      Origin = 'HRK2302.PENZTARSZAM'
    end
    object HUFQUERYPENZTARKOD: TIBStringField
      FieldName = 'PENZTARKOD'
      Origin = 'HRK2302.PENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object HUFQUERYPENZTARNEV: TIBStringField
      FieldName = 'PENZTARNEV'
      Origin = 'HRK2302.PENZTARNEV'
      FixedChar = True
      Size = 30
    end
    object HUFQUERYV1: TIntegerField
      FieldName = 'V1'
      Origin = 'HRK2302.V1'
    end
    object HUFQUERYE1: TIntegerField
      FieldName = 'E1'
      Origin = 'HRK2302.E1'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV2: TIntegerField
      FieldName = 'V2'
      Origin = 'HRK2302.V2'
    end
    object HUFQUERYE2: TIntegerField
      FieldName = 'E2'
      Origin = 'HRK2302.E2'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV3: TIntegerField
      FieldName = 'V3'
      Origin = 'HRK2302.V3'
    end
    object HUFQUERYE3: TIntegerField
      FieldName = 'E3'
      Origin = 'HRK2302.E3'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV4: TIntegerField
      FieldName = 'V4'
      Origin = 'HRK2302.V4'
    end
    object HUFQUERYE4: TIntegerField
      FieldName = 'E4'
      Origin = 'HRK2302.E4'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV5: TIntegerField
      FieldName = 'V5'
      Origin = 'HRK2302.V5'
    end
    object HUFQUERYE5: TIntegerField
      FieldName = 'E5'
      Origin = 'HRK2302.E5'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV6: TIntegerField
      FieldName = 'V6'
      Origin = 'HRK2302.V6'
    end
    object HUFQUERYE6: TIntegerField
      FieldName = 'E6'
      Origin = 'HRK2302.E6'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV7: TIntegerField
      FieldName = 'V7'
      Origin = 'HRK2302.V7'
    end
    object HUFQUERYE7: TIntegerField
      FieldName = 'E7'
      Origin = 'HRK2302.E7'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV8: TIntegerField
      FieldName = 'V8'
      Origin = 'HRK2302.V8'
    end
    object HUFQUERYE8: TIntegerField
      FieldName = 'E8'
      Origin = 'HRK2302.E8'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV9: TIntegerField
      FieldName = 'V9'
      Origin = 'HRK2302.V9'
    end
    object HUFQUERYE9: TIntegerField
      FieldName = 'E9'
      Origin = 'HRK2302.E9'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV10: TIntegerField
      FieldName = 'V10'
      Origin = 'HRK2302.V10'
    end
    object HUFQUERYE10: TIntegerField
      FieldName = 'E10'
      Origin = 'HRK2302.E10'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV11: TIntegerField
      FieldName = 'V11'
      Origin = 'HRK2302.V11'
    end
    object HUFQUERYE11: TIntegerField
      FieldName = 'E11'
      Origin = 'HRK2302.E11'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV12: TIntegerField
      FieldName = 'V12'
      Origin = 'HRK2302.V12'
    end
    object HUFQUERYE12: TIntegerField
      FieldName = 'E12'
      Origin = 'HRK2302.E12'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV13: TIntegerField
      FieldName = 'V13'
      Origin = 'HRK2302.V13'
    end
    object HUFQUERYE13: TIntegerField
      FieldName = 'E13'
      Origin = 'HRK2302.E13'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV14: TIntegerField
      FieldName = 'V14'
      Origin = 'HRK2302.V14'
    end
    object HUFQUERYE14: TIntegerField
      FieldName = 'E14'
      Origin = 'HRK2302.E14'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV15: TIntegerField
      FieldName = 'V15'
      Origin = 'HRK2302.V15'
    end
    object HUFQUERYE15: TIntegerField
      FieldName = 'E15'
      Origin = 'HRK2302.E15'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV16: TIntegerField
      FieldName = 'V16'
      Origin = 'HRK2302.V16'
    end
    object HUFQUERYE16: TIntegerField
      FieldName = 'E16'
      Origin = 'HRK2302.E16'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV17: TIntegerField
      FieldName = 'V17'
      Origin = 'HRK2302.V17'
    end
    object HUFQUERYE17: TIntegerField
      FieldName = 'E17'
      Origin = 'HRK2302.E17'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV18: TIntegerField
      FieldName = 'V18'
      Origin = 'HRK2302.V18'
    end
    object HUFQUERYE18: TIntegerField
      FieldName = 'E18'
      Origin = 'HRK2302.E18'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV19: TIntegerField
      FieldName = 'V19'
      Origin = 'HRK2302.V19'
    end
    object HUFQUERYE19: TIntegerField
      FieldName = 'E19'
      Origin = 'HRK2302.E19'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV20: TIntegerField
      FieldName = 'V20'
      Origin = 'HRK2302.V20'
    end
    object HUFQUERYE20: TIntegerField
      FieldName = 'E20'
      Origin = 'HRK2302.E20'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV21: TIntegerField
      FieldName = 'V21'
      Origin = 'HRK2302.V21'
    end
    object HUFQUERYE21: TIntegerField
      FieldName = 'E21'
      Origin = 'HRK2302.E21'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV22: TIntegerField
      FieldName = 'V22'
      Origin = 'HRK2302.V22'
    end
    object HUFQUERYE22: TIntegerField
      FieldName = 'E22'
      Origin = 'HRK2302.E22'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV23: TIntegerField
      FieldName = 'V23'
      Origin = 'HRK2302.V23'
    end
    object HUFQUERYE23: TIntegerField
      FieldName = 'E23'
      Origin = 'HRK2302.E23'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV24: TIntegerField
      FieldName = 'V24'
      Origin = 'HRK2302.V24'
    end
    object HUFQUERYE24: TIntegerField
      FieldName = 'E24'
      Origin = 'HRK2302.E24'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV25: TIntegerField
      FieldName = 'V25'
      Origin = 'HRK2302.V25'
    end
    object HUFQUERYE25: TIntegerField
      FieldName = 'E25'
      Origin = 'HRK2302.E25'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV26: TIntegerField
      FieldName = 'V26'
      Origin = 'HRK2302.V26'
    end
    object HUFQUERYE26: TIntegerField
      FieldName = 'E26'
      Origin = 'HRK2302.E26'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV27: TIntegerField
      FieldName = 'V27'
      Origin = 'HRK2302.V27'
    end
    object HUFQUERYE27: TIntegerField
      FieldName = 'E27'
      Origin = 'HRK2302.E27'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV28: TIntegerField
      FieldName = 'V28'
      Origin = 'HRK2302.V28'
    end
    object HUFQUERYE28: TIntegerField
      FieldName = 'E28'
      Origin = 'HRK2302.E28'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV29: TIntegerField
      FieldName = 'V29'
      Origin = 'HRK2302.V29'
    end
    object HUFQUERYE29: TIntegerField
      FieldName = 'E29'
      Origin = 'HRK2302.E29'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV30: TIntegerField
      FieldName = 'V30'
      Origin = 'HRK2302.V30'
    end
    object HUFQUERYE30: TIntegerField
      FieldName = 'E30'
      Origin = 'HRK2302.E30'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYV31: TIntegerField
      FieldName = 'V31'
      Origin = 'HRK2302.V31'
    end
    object HUFQUERYE31: TIntegerField
      FieldName = 'E31'
      Origin = 'HRK2302.E31'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYVSUM: TIntegerField
      FieldName = 'VSUM'
      Origin = 'HRK2302.VSUM'
    end
    object HUFQUERYESUM: TIntegerField
      FieldName = 'ESUM'
      Origin = 'HRK2302.ESUM'
      DisplayFormat = '### ### ###'
    end
    object HUFQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'HRK2302.ERTEKTAR'
    end
    object HUFQUERYKORZETNEV: TIBStringField
      FieldName = 'KORZETNEV'
      Origin = 'HRK2302.KORZETNEV'
      FixedChar = True
      Size = 15
    end
  end
  object HUFDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\HRKSERVER.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HUFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 696
    Top = 72
  end
  object HUFTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = HUFDBASE
    AutoStopAction = saNone
    Left = 728
    Top = 72
  end
end
