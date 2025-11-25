object HAVITABLO: THAVITABLO
  Left = 245
  Top = 138
  BorderStyle = bsNone
  Caption = 'HAVITABLO'
  ClientHeight = 941
  ClientWidth = 1159
  Color = clSkyBlue
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object GRAFIKONPANEL: TPanel
    Left = 21
    Top = 20
    Width = 961
    Height = 530
    Color = clAqua
    TabOrder = 0
    OnExit = GrafikonPanelExit
    object GRAFIKON: TChart
      Left = 104
      Top = 40
      Width = 400
      Height = 305
      BackWall.Brush.Color = clWhite
      BackWall.Brush.Style = bsClear
      Title.Text.Strings = (
        '')
      BottomAxis.Automatic = False
      BottomAxis.AutomaticMaximum = False
      BottomAxis.AutomaticMinimum = False
      BottomAxis.ExactDateTime = False
      BottomAxis.LabelsMultiLine = True
      BottomAxis.LabelsOnAxis = False
      BottomAxis.LabelsSize = 100
      BottomAxis.TickLength = 0
      BottomAxis.TickOnLabelsOnly = False
      TabOrder = 0
    end
    object GroupBox1: TGroupBox
      Left = 760
      Top = 112
      Width = 153
      Height = 81
      TabOrder = 1
      object CSAKVASAR: TRadioButton
        Left = 8
        Top = 16
        Width = 145
        Height = 17
        Caption = 'V'#193'S'#193'RL'#193'SOK'
        Checked = True
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
        TabStop = True
        OnClick = CSAKVASARClick
      end
      object CSAKELADAS: TRadioButton
        Left = 8
        Top = 48
        Width = 113
        Height = 17
        Caption = 'ELAD'#193'SOK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = CSAKELADASClick
      end
    end
    object KORDIAGRAMGOMB: TBitBtn
      Left = 824
      Top = 496
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'RDIAGRAM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = KORDIAGRAMGOMBClick
    end
    object ALSOCIMPANEL: TPanel
      Left = 208
      Top = 496
      Width = 401
      Height = 25
      BevelOuter = bvNone
      Color = clAqua
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object korforgalompanel: TPanel
      Left = 200
      Top = 32
      Width = 961
      Height = 529
      Color = clBlue
      TabOrder = 4
      object KORDIAGRAM: TChart
        Left = 224
        Top = 72
        Width = 961
        Height = 489
        AllowPanning = pmNone
        AllowZoom = False
        BackWall.Brush.Color = clWhite
        BackWall.Brush.Style = bsClear
        BackWall.Pen.Visible = False
        Gradient.EndColor = 16777088
        Gradient.StartColor = clBlue
        Gradient.Visible = True
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -24
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Title.Text.Strings = (
          'TChart')
        AxisVisible = False
        ClipPoints = False
        Frame.Visible = False
        View3DOptions.Elevation = 315
        View3DOptions.Orthogonal = False
        View3DOptions.Perspective = 0
        View3DOptions.Rotation = 360
        View3DWalls = False
        TabOrder = 0
        object NAPIKORFORGALOM: TPieSeries
          Marks.ArrowLength = 8
          Marks.Visible = True
          SeriesColor = clRed
          OtherSlice.Text = 'Other'
          PieValues.DateTime = False
          PieValues.Name = 'Pie'
          PieValues.Multiplier = 1
          PieValues.Order = loNone
        end
      end
      object Button6: TButton
        Left = 16
        Top = 496
        Width = 225
        Height = 25
        Caption = 'NAPI V'#193'S'#193'RL'#193'SOK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = F1GOMBClick
      end
      object Button7: TButton
        Left = 248
        Top = 496
        Width = 225
        Height = 25
        Caption = 'NAPI ELAD'#193'SOK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = F2GOMBClick
      end
      object Button8: TButton
        Left = 480
        Top = 496
        Width = 225
        Height = 25
        Caption = 'NAPI FORGALOM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        OnClick = F3GOMBClick
      end
      object Button9: TButton
        Left = 712
        Top = 496
        Width = 225
        Height = 25
        Caption = 'VISSZA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        OnClick = Button9Click
      end
    end
  end
  object Button1: TButton
    Left = 152
    Top = 728
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 1
    OnClick = Button1Click
  end
end
