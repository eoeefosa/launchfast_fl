const { MongoClient, ObjectId } = require('mongodb');

const uri = "mongodb+srv://eoeefosa_db_user:y2JSVbnyWBnrhzw0@cluster0.covouhe.mongodb.net/launchfast_db?retryWrites=true&w=majority&authSource=admin&appName=Cluster0";

async function run() {
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const database = client.db('launchfast_db');
    const orders = database.collection('orders');

    // Find all orders where userId is not null
    const cursor = orders.find({ userId: { $ne: null } });
    let count = 0;
    
    for await (const doc of cursor) {
      if (doc.userId && !ObjectId.isValid(doc.userId)) {
        console.log(`Fixing order ${doc._id} with invalid userId ${doc.userId}`);
        await orders.updateOne(
          { _id: doc._id },
          { $set: { userId: null } }
        );
        count++;
      }
    }
    
    console.log(`Fixed ${count} orders.`);
  } finally {
    await client.close();
  }
}

run().catch(console.dir);
