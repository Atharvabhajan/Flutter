const mongoose = require("mongoose");
const EmergencyContact = require("../models/EmergencyContact");
const { sendSuccess, sendError } = require("../utils/response");

// @desc    Add emergency contact
// @route   POST /api/contacts
// @access  Private
exports.addContact = async (req, res) => {
  try {
    const { name, phone, relation, email, priority, telegramChatId } = req.body;

    const contact = await EmergencyContact.create({
      userId: req.userId,
      name,
      phone,
      relation,
      email,
      telegramChatId,
      priority: priority || 1,
    });

    return sendSuccess(res, 201, "Emergency contact added successfully", contact);
  } catch (error) {
    console.error("Add contact error:", error);
    return sendError(res, 500, "Error adding contact");
  }
};

// @desc    Get all emergency contacts for user
// @route   GET /api/contacts
// @access  Private
exports.getContacts = async (req, res) => {
  try {
    const contacts = await EmergencyContact.find({ userId: req.userId }).sort({ priority: 1 });

    return sendSuccess(res, 200, "Contacts retrieved successfully", {
      count: contacts.length,
      items: contacts,
    });
  } catch (error) {
    console.error("Get contacts error:", error);
    return sendError(res, 500, "Error fetching contacts");
  }
};

// @desc    Update emergency contact
// @route   PUT /api/contacts/:id
// @access  Private
exports.updateContact = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Invalid contact ID");
    }

    const contact = await EmergencyContact.findById(id);
    if (!contact) return sendError(res, 404, "Contact not found");
    if (contact.userId.toString() !== req.userId) {
      return sendError(res, 403, "Not authorized to update this contact");
    }

    // Only apply fields that were actually sent
    const { name, phone, relation, email, priority, telegramChatId } = req.body;
    const updates = {};
    if (name      !== undefined) updates.name     = name;
    if (phone     !== undefined) updates.phone    = phone;
    if (relation  !== undefined) updates.relation = relation;
    if (email     !== undefined) updates.email    = email;
    if (priority  !== undefined) updates.priority = priority;
    if (telegramChatId !== undefined) updates.telegramChatId = telegramChatId;

    const updated = await EmergencyContact.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    });

    return sendSuccess(res, 200, "Contact updated successfully", updated);
  } catch (error) {
    console.error("Update contact error:", error);
    return sendError(res, 500, "Error updating contact");
  }
};

// @desc    Delete emergency contact
// @route   DELETE /api/contacts/:id
// @access  Private
exports.deleteContact = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Invalid contact ID");
    }

    const contact = await EmergencyContact.findById(id);
    if (!contact) return sendError(res, 404, "Contact not found");
    if (contact.userId.toString() !== req.userId) {
      return sendError(res, 403, "Not authorized to delete this contact");
    }

    await EmergencyContact.findByIdAndDelete(id);

    return sendSuccess(res, 200, "Contact deleted successfully");
  } catch (error) {
    console.error("Delete contact error:", error);
    return sendError(res, 500, "Error deleting contact");
  }
};
