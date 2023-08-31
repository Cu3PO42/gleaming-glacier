{lib, ...}: {
  system.defaults = {
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = false;
      "com.apple.trackpad.scaling" = 3.0;
    };
    ".GlobalPreferences"."com.apple.mouse.scaling" = "2.5";
    CustomSystemPreferences = let
      m = with lib; mapAttrs (outer: mapAttrs' (inner: nameValuePair "${outer}.${inner}"));
    in
      m {
        "com.apple.AppleMultiTouchMouse" = {
          MouseButtonDivision = 55;
          MouseButtonMode = "TwoButton";
          MouseHorizontalScroll = 1;
          MouseMomentumScroll = 0;
          MouseOneFingerDoubleTapGesture = 0;
          MouseTwoFingerDoubleTapGesture = 3;
          MouseTwoFingerHorizSwipeGesture = 2;
          MouseVerticalScroll = 1;
        };
        "com.apple.AppleMultitouchTrackpad" = {
          TrackpadCornerSecondaryClick = 0;
          TrackpadFiveFingerPinchGesture = 2;
          TrackpadFourFingerHorizSwipeGesture = 2;
          TrackpadFourFingerPinchGesture = 2;
          TrackpadFourFingerVertSwipeGesture = 2;
          TrackpadHandResting = 1;
          TrackpadHorizScroll = 1;
          TrackpadMomentumScroll = 1;
          TrackpadPinch = 1;
          TrackpadRightClick = 1;
          TrackpadRotate = 1;
          TrackpadScroll = 1;
          TrackpadThreeFingerDrag = 0;
          TrackpadThreeFingerHorizSwipeGesture = 2;
          TrackpadThreeFingerTapGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 2;
          TrackpadTwoFingerDoubleTapGesture = 1;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        };
      };
  };
}
