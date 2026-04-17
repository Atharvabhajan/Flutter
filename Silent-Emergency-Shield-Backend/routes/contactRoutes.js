const express = require("express");
const {
  addContact,
  getContacts,
  updateContact,
  deleteContact,
} = require("../controllers/contactController");
const authMiddleware = require("../middlewares/authMiddleware");
const {
  handleValidation,
  addContactRules,
  updateContactRules,
} = require("../middlewares/validate");

const router = express.Router();

router.use(authMiddleware);

router.post("/",    addContactRules,    handleValidation, addContact);
router.get("/",                                           getContacts);
router.put("/:id",  updateContactRules, handleValidation, updateContact);
router.delete("/:id",                                     deleteContact);

module.exports = router;
