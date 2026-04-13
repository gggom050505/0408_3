const passport = require('passport');
const KakaoStrategy = require('passport-kakao').Strategy;

function setupPassport() {
  passport.serializeUser((user, done) => done(null, user));
  passport.deserializeUser((obj, done) => done(null, obj));

  const clientID = process.env.KAKAO_CLIENT_ID || '';
  const callbackURL = process.env.KAKAO_CALLBACK_URL || '';

  if (!clientID || !callbackURL) {
    return;
  }

  passport.use(
    new KakaoStrategy(
      {
        clientID,
        callbackURL,
      },
      (accessToken, refreshToken, profile, done) => {
        const user = {
          provider: 'kakao',
          id: String(profile.id),
          username: profile.username || '',
          displayName: profile.displayName || '',
          accessToken,
        };
        done(null, user);
      },
    ),
  );
}

module.exports = { setupPassport, passport };
