onst { Client } = require('pg');

exports.handler = async (event) => {

// Create a NEW client inside handler (not globally)
const client = new Client({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: 5432,
    ssl: {
    rejectUnauthorized: false   // IMPORTANT for RDS
    }
    });
    
    await client.connect();

    const method = event.httpMethod;
    let body = {};

    try {
        if (method === 'POST') {
            const data = JSON.parse(event.body);
            const res = await client.query(
                'INSERT INTO users(name, email) VALUES($1, $2) RETURNING *',
                [data.name, data.email]
            );
            body = res.rows[0];

        } else if (method === 'GET') {
            const id = event.pathParameters ? event.pathParameters.id : null;
            const res = id
                ? await client.query('SELECT * FROM users WHERE id=$1', [id])
                : await client.query('SELECT * FROM users');
            body = res.rows;

        } else if (method === 'PUT') {
            const id = event.pathParameters.id;
            const data = JSON.parse(event.body);
            const res = await client.query(
                'UPDATE users SET name=$1, email=$2 WHERE id=$3 RETURNING *',
                [data.name, data.email, id]
            );
            body = res.rows[0];

        } else if (method === 'DELETE') {
            const id = event.pathParameters.id;
            await client.query('DELETE FROM users WHERE id=$1', [id]);
            body = { message: 'Deleted successfully' };

        } else {
            body = { message: 'Unsupported method' };
        }

    } catch (err) {
        body = { error: err.message };

    } finally {
        await client.end(); // always close the connection
    }

    return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
    };
};

