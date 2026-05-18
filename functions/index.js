const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors({origin: true}));
app.use(express.json());

// TEMP USERS — replace with Firestore later
const users = [
  {
    userId: "Abhi 001",
    name: "BALAJI",
    mobile: "8825656218",
    password: "balaji",
    role: "master",
    createdAt: "22-11-2025",
    segment: "all",
  },
];

app.post("/login", (req, res) => {
  const {mobile, password} = req.body;

  if (!mobile || !password) {
    return res.json({status: "error", message: "Missing fields"});
  }

  const user = users.find(
      (u) => u.mobile === mobile && u.password === password);

  if (!user) {
    return res.json({status: "error", message: "Invalid mobile/password"});
  }

  return res.json({
    status: "success",
    user: user,
  });
});

exports.api = functions.https.onRequest(app);
