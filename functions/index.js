
const functions = require("firebase-functions");
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const log = require("firebase-functions/logger/compat");

admin.initializeApp();

// Send 'Report User' Email to Helpdesk

const tranporter = nodemailer.createTransport({

  service: 'gmail',
  auth: {
    user: 'jakegordon53@gmail.com',
    pass: 'aahh qckt gmtr gyyf'
  },
});

exports.sendReportUserEmail = functions.firestore.document('userReports/{reportId}')
.onCreate((snapshot, context) => {

  const newReportData = snapshot.data();
  const mailOptions = {
    from: 'jakegordon53@gmail.com',
    to: 'jakegordon53@gmail.com',
    subject: 'New Just Friends User Report Created',
    text: `Report: ${JSON.stringify(newReportData)}`,
  };

  return tranporter.sendMail(mailOptions, (error, info) => {
  if (error) {
    console.error('Error sending email:', error);
  } else {
    console.log('Email sent:', info.response);
  }
  });
});


// Send Notification for New Friend Request


exports.notifyUser = functions.https.onCall((data, context) => {
  const deviceToken = data.tappedID;
  const tapperID = data.tapperID;
  const tapperName = data.tapperName;
  const message = `${tapperName} wants to be friends with you.`;
  
  const payload = {
  notification: {
  title: "You sure are popular!",
  body: message,
  },
  token: deviceToken,
  };
  
  return admin.messaging().send(payload)
  .then(() => {
  console.log("notification sent successfully");
  return null;
  })
  .catch((error) => {
  console.error("error sending notification: ", error);
  return null;
  })
  .catch((error) => {
  console.error("error fetching user document: ", error);
  return null;
  });
  });
  

  // Send Notification for Friend Request Acceptance
  

  exports.confirmMatch = functions.https.onCall((data, context) => {
    const suitor = data.suitor;
    const suitee = data.suitee;
    const suiteeName = data.suiteeName;
    const message = `${suiteeName} has accepted your request.`;
    
    const payload = {
    notification: {
    title: "You've made a new friend!",
    body: message,
    },
    token: suitor,
    };
    
    return admin.messaging().send(payload)
    .then(() => {
    console.log("notification sent successfully");
    return null;
    })
    .catch((error) => {
    console.error("error sending notification: ", error);
    return null;
    })
    .catch((error) => {
    console.error("error fetching user document: ", error);
    return null;
    });
    });


    // Send new Message notification

    exports.sendChatMessageNotification = functions.https.onCall((data, context) => {
      const deviceToken = data.receiverID;
      const senderName = data.senderName;
      const chatText = data.chatText;
      const message = `${chatText}`;
      
      const payload = {
      notification: {
      title: senderName,
      body: message,
      },
      token: deviceToken,
      };
      
      return admin.messaging().send(payload)
      .then(() => {
      console.log("notification sent successfully");
      return null;
      })
      .catch((error) => {
      console.error("error sending notification: ", error);
      return null;
      })
      .catch((error) => {
      console.error("error fetching user document: ", error);
      return null;
      });
      });