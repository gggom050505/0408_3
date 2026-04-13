require('dotenv').config();

const express = require('express');
const session = require('express-session');
const { setupPassport, passport } = require('./passport');

const app = express();
const port = Number(process.env.PORT || 4000);
const sessionSecret = process.env.SESSION_SECRET || 'dev-only-secret';
const clientRedirectUrl = process.env.CLIENT_REDIRECT_URL || 'http://localhost:59448';

setupPassport();

app.use(express.json());
app.use(
  session({
    secret: sessionSecret,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: 'lax',
      secure: false,
      maxAge: 1000 * 60 * 60 * 24 * 14,
    },
  }),
);
app.use(passport.initialize());
app.use(passport.session());

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'gggom-auth-server' });
});

app.get('/auth/kakao', (req, res, next) => {
  if (!process.env.KAKAO_CLIENT_ID || !process.env.KAKAO_CALLBACK_URL) {
    return res.status(500).json({
      ok: false,
      message: 'KAKAO_CLIENT_ID / KAKAO_CALLBACK_URL 환경변수가 필요합니다.',
    });
  }
  return passport.authenticate('kakao')(req, res, next);
});

app.get(
  '/auth/kakao/callback',
  passport.authenticate('kakao', {
    failureRedirect: '/auth/fail',
    session: true,
  }),
  (req, res) => {
    res.redirect(`${clientRedirectUrl}?auth=kakao-success`);
  },
);

app.get('/auth/fail', (req, res) => {
  res.status(401).send('카카오 로그인에 실패했습니다.');
});

app.get('/auth/session', (req, res) => {
  if (!req.isAuthenticated || !req.isAuthenticated()) {
    return res.status(401).json({ ok: false, authenticated: false });
  }
  return res.json({
    ok: true,
    authenticated: true,
    user: req.user,
  });
});

app.post('/auth/logout', (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ ok: false, message: 'logout failed' });
    }
    req.session.destroy(() => {
      res.json({ ok: true });
    });
  });
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Auth server listening on http://localhost:${port}`);
});
