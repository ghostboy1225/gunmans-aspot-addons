//below is a WIP and shouldn't be useable
//
// This file is part of ASPOT.
// See README and LICENSE for details.
//

// -------------------------------------------------------------------------- //

class AS_addon_seige_v2 : ASpotStyle {

  enum EIconType {

    ICON_RUN,
    ICON_DOT,
    ICON_ATTACK,
	ICON_ASSIST,

    NUM_ICONS

  };

  protected TextureID mTex[NUM_ICONS];

  override string GetStyleName() const {
    return "siegetest";
  }

  override bool LoadStyle() {
    static const string TEXNAMES[] = {
      "ASPOTRUN", "ASPOTDOT", "ASPOTATK", "ASPOTASSIST"
    };

    for (int i = 0; i < NUM_ICONS; ++i) {
      mTex[i] = TexMan.CheckForTexture(TEXNAMES[i], TexMan.Type_Any);

      if (!mTex[i].isValid()) {
        Console.Printf("aspot: missing graphic '%s'", TEXNAMES[i]);
        return false;
      }
    }

    return true;
  }

  override Actor SpawnSpot(
    in ASpotSpotData spot,
    PlayerPawn player,
    in FLineTraceData trace,
    Actor mob,
    ASpotType type
  ) {
    string username = player.player.GetUserName();
    Actor icon = null;

    switch (type) {
      case ASPOT_FRIEND:
      case ASPOT_MONSTER: {
        icon = Actor.Spawn('ASpotIconAttack', trace.HitLocation);

        if (mob != null) {
          string tagname = mob.GetTag();

          if (mob is 'PlayerPawn') {
            tagname = mob.player.GetUserName();
          }

          Console.PrintF("\c[RED]%s wants to attack: %s.", username, tagname);
        }

        break;
      }
      case ASPOT_PICKUP: {
        icon = Actor.Spawn('ASpotIconDot_siege', trace.HitLocation);

        if (mob != null) {
          string tagname = mob.GetTag();
          Console.PrintF("\c[GOLD]%s has found: %s.", username, tagname);
        }

        break;
      }
      default: {
        icon = Actor.Spawn('ASpotIconRun', trace.HitLocation);
        Console.PrintF("\c[GREEN]%s wants to move here.", username);
        break;
      }
    }

    if (icon != null) {
      icon.tracer = mob;

      if (trace.HitType == TRACE_HitWall) {
        icon.angle = player.angle;
        icon.Warp(icon, xofs: -2.0);
      }

      switch (trace.HitType) {
        case TRACE_HitFloor:
        case TRACE_HitCeiling: {
          icon.bFLATSPRITE = true;
          break;
        }
        case TRACE_HitActor: {
          icon.bFORCEXYBILLBOARD = true;
          break;
        }
      }
    }

    return icon;
  }

  override void DrawSpot(
    in ASpotSpotData spot,
    PlayerPawn player,
    in ASpotScreen ascreen,
    ASpotCamera acamera,
    RenderEvent e
  ) {
    Actor mo = spot.GetActor();

    if (mo == null) {
      return;
    }

    acamera.ProjectActorPosPortal(
      mo, (0, 0, (mo.Height / 2)), e.FracTic
    );

    TextureID tex;
    int rgba = 0xFFFFFFFF;

    switch (spot.type) {
      default: {
        tex = mTex[ICON_RUN];
        rgba = 0xFFC8FFC1; // Font.CR_GREEN;
        break;
      }
      case ASPOT_FRIEND:
      case ASPOT_MONSTER: {
        tex = mTex[ICON_ATTACK];
        rgba = 0xFFF56564; // Font.CR_RED;
        break;
      }
      case ASPOT_PICKUP: {
        tex = mTex[ICON_DOT];
        rgba = 0xFFF7F573; // Font.CR_GOLD;
        break;
      }
    }

    vector2 pos = Calc2DPos(ascreen, acamera, (80, 40));
    Screen.DrawTexture(tex, true, pos.x, pos.y);

    if (CONFONT) {
      string username = player.player.GetUserName();
      int width = CONFONT.StringWidth(username);
      int height = CONFONT.GetHeight();

      Screen.DrawText(
        CONFONT, Font.CR_UNTRANSLATED,
        (pos.X - 0.5 * width), (pos.Y - 24 - height), username,
        DTA_Color, rgba, DTA_Desaturate, 255
      );
    }
  }

}

// -------------------------------------------------------------------------- //

class ASpotIconRun_siege : Actor {

  protected int mRingSpawnTimer;

  Default {

    +NOINTERACTION
    +NOGRAVITY
    +NOBLOCKMAP

    Radius 1;
    Height 1;

  }

  override void BeginPlay() {
    super.BeginPlay();
    mRingSpawnTimer = 0;
  }

  override void Tick() {
    super.Tick();

    if (--mRingSpawnTimer <= 0) {
      Actor ring = Actor.Spawn('ASpotIconRunRing_siege', Pos);

      if (ring != null) {
        ring.master = self;
        ring.tracer = tracer;
        ring.bFLATSPRITE = bFLATSPRITE;
        ring.bFORCEXYBILLBOARD = bFORCEXYBILLBOARD;
      
        if (tracer != null) {
          ring.Warp(
            tracer, zofs: (tracer.Height / 2),
            flags: WARPF_INTERPOLATE
          );
        }
      }

      mRingSpawnTimer = 23;
    }
  }

  States {

    Spawn:
      TNT1 AAAAAAAA 35;
      Stop;

  }

}

class ASpotIconRunRing_siege : Actor {

  Default {

    +NOINTERACTION
    +NOGRAVITY
    +NOBLOCKMAP

    Radius 1;
    Height 1;
    Scale 0.125;
    RenderStyle "AddStencil";
    StencilColor "00 FF 00";

  }

  States {

    Spawn:
      ARNG C 1 {
        if (tracer != null) {
          Warp(
            tracer, zofs: (tracer.Height / 2),
            flags: WARPF_INTERPOLATE
          );
        }

        A_SetScale(Scale.X + 0.0175);
        A_FadeOut(0.02, (FTF_REMOVE | FTF_CLAMP));
      }
      Loop;

  }

}

// -------------------------------------------------------------------------- //

class ASpotIconDot_siege : Actor {

  protected int mRingSpawnTimer;

  Default {

    +NOINTERACTION
    +NOGRAVITY
    +NOBLOCKMAP

    Radius 1;
    Height 1;

  }

  override void BeginPlay() {
    super.BeginPlay();
    mRingSpawnTimer = 0;
  }

  override void Tick() {
    super.Tick();

    if (--mRingSpawnTimer <= 0) {
      Actor ring = Actor.Spawn('ASpotIconDotRing_siege', Pos);

      if (ring != null) {
        ring.master = self;
        ring.tracer = tracer;
        ring.bFLATSPRITE = bFLATSPRITE;
        ring.bFORCEXYBILLBOARD = bFORCEXYBILLBOARD;
      
        if (tracer != null) {
          ring.Warp(
            tracer, zofs: (tracer.Height / 2),
            flags: WARPF_INTERPOLATE
          );
        }
      }

      mRingSpawnTimer = 35;
    }
  }

  States {

    Spawn:
      TNT1 AAAAAAAA 35;
      Stop;

  }

}

class ASpotIconDotRing_siege : Actor {

  Default {

    +NOINTERACTION
    +NOGRAVITY
    +NOBLOCKMAP

    Radius 1;
    Height 1;
    Scale 0.125;
    RenderStyle "AddStencil";
    StencilColor "FF FF 00";

  }

  States {

    Spawn:
      ARNG D 1 {
        if (tracer != null) {
          Warp(
            tracer, zofs: (tracer.Height / 2),
            flags: WARPF_INTERPOLATE
          );
        }

        A_SetScale(Scale.X + 0.0175);
        A_FadeOut(0.02, (FTF_REMOVE | FTF_CLAMP));
      }
      Loop;

  }

}

// -------------------------------------------------------------------------- //

class ASpotIconAttack_siege : Actor {

  Default {

    +NOINTERACTION
    +NOGRAVITY
    +NOBLOCKMAP

    Radius 1;
    Height 1;
    Alpha 0.4;
    RenderStyle "AddStencil";
    StencilColor "FF 00 00";

  }

  override void Tick() {
    super.Tick();

    if (tracer != null && !(tracer is 'PlayerPawn')) {
      self.sprite  = tracer.sprite;
      self.frame   = tracer.frame;
      self.scale   = tracer.scale;

      // TODO: outlines?
      // self.scale.x = (tracer.scale.x + 0.1);
      // self.scale.y = (tracer.scale.y + 0.1);

      self.bFORCEYBILLBOARD = tracer.bFORCEYBILLBOARD;
      self.bFORCEXYBILLBOARD = tracer.bFORCEXYBILLBOARD;

      Warp(tracer, flags: (WARPF_COPYVELOCITY | WARPF_INTERPOLATE));
    }
  }

  States {

    Spawn:
      TNT1 AAAAAAAA 35 nodelay;
      Stop;

  }

}

// -------------------------------------------------------------------------- //
