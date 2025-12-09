const { Client } = require('pg');

exports.handler = async (event) => {
    // Create a NEW client inside handler
    const client = new Client({
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        port: 5432,
        ssl: { rejectUnauthorized: false } // IMPORTANT for RDS
    });

    await client.connect();

    const method = event.httpMethod;
    let body = {};
    let statusCode = 200; // default

    try {
        if (method === 'POST') {
            const data = JSON.parse(event.body);
            const res = await client.query(
                'INSERT INTO users(name, email) VALUES($1, $2) RETURNING *',
                [data.name, data.email]
            );
            body = res.rows[0];
            statusCode = 201; // Created

        } else if (method === 'GET') {
            const id = event.pathParameters ? event.pathParameters.id : null;
            const res = id
                ? await client.query('SELECT * FROM users WHERE id=$1', [id])
                : await client.query('SELECT * FROM users');
            if (id) {
                if (!res.rows[0]) {
                    body = { message: 'User not found' };
                    statusCode = 404; // Not found
                } else {
                    body = res.rows[0];
                    statusCode = 200;
                }
            } else {
                body = res.rows;
                statusCode = 200;
            }

        } else if (method === 'PUT') {
            const id = event.pathParameters.id;
            const data = JSON.parse(event.body);
            const res = await client.query(
                'UPDATE users SET name=$1, email=$2 WHERE id=$3 RETURNING *',
                [data.name, data.email, id]
            );
            if (!res.rows[0]) {
                body = { message: 'User not found' };
                statusCode = 404;
            } else {
                body = res.rows[0];
                statusCode = 200;
            }

        } else if (method === 'DELETE') {
            const id = event.pathParameters.id;
            const res = await client.query('DELETE FROM users WHERE id=$1 RETURNING *', [id]);
            if (!res.rows[0]) {
                body = { message: 'User not found' };
                statusCode = 404;
            } else {
                body = { message: 'Deleted successfully' };
                statusCode = 200;
            }

        } else {
            body = { message: 'Unsupported method' };
            statusCode = 400;
        }

    } catch (err) {
        body = { error: err.message };
        statusCode = 500;

    } finally {
        await client.end(); // always close the connection
    }

    return {
        statusCode,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
    };
};
