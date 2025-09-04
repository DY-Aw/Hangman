const path = require('path');
require('dotenv').config({
    override: true,
    path: path.join(__dirname, 'development.env')
});
const {Pool, Client} = require('pg');
const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.urlencoded({extended: true}))

const pool = new Pool({
    user: process.env.USER,
    host: process.env.HOST,
    database: process.env.DATABASE,
    password: process.env.PASSWORD,
    port: process.env.PORT
});

(async () => {
    const client = await pool.connect();
    try {
        const resp = await client.query('SELECT * FROM words');
        const currentUser = resp.rows;
        console.log(currentUser); 
    } catch (err) {
        console.error(err);
    } finally {
        client.release();
    }
})();

app.get('/ping', (req, res) => {
    console.log('Received ping!');
    res.status(200).json({message: 'Ping successful!'})
});

app.listen(port, () => {
    console.log('Server is running at http://localhost:${port}');
});

app.post('/login', async(req, res) => {
    const {username} = req.body;

    const client = await pool.connect();
    try {
        const query =  `
        INSERT INTO users (username)
        VALUES ($1)
        ON CONFLICT (username) DO NOTHING
        `;
        const values = [username];
        const result = await client.query(query, values);
        console.log('Updated successfully');
        console.log('Logged in with username: ', username)
    } catch (err) {
        console.error('Error updating login information', err);
    } finally {
        client.release();
    }
})

app.get('/returnUserID', async(req, res) => {
    const username = req.query.username;

    const client = await pool.connect();
    try {
        const result = await client.query(
            'SELECT id FROM users WHERE username = $1',
            [username]
        );
        if (result.rows.length > 0) {
            const userID = result.rows[0].id;
            console.log('User ID for ${username} is: ${userID}');
            console.log(userID);
            console.log(typeof userID)
            res.json(userID);
        } else {
            console.log('User not found with username: ${username}');
            res.json(null);
        }
    } catch (err) {
        console.log("Failed to return ID: ", err);
    } finally {
        client.release();
    }
})

app.post('/update', async (req, res) => {
    const {word, win} = req.body;
    
    const client = await pool.connect();
    try {
        const query = `
            INSERT INTO words (word, times_played, times_won, times_lost)
            VALUES ($1, 1, $2, (1-$2))
            ON CONFLICT (word)
            DO UPDATE SET
                times_played = words.times_played + 1,
                times_won = words.times_won + $2,
                times_lost = words.times_lost + (1 - $2)
            RETURNING *;
        `;
        const values = [word, win];
        const result = await client.query(query, values);
        console.log("Updated successfully")
    } catch (err) {
        console.error('Error updating word stats:', err);
    } finally {
        client.release();
    }
})

app.post('/updatestats', async (req, res) => {
    const {id, word, win} = req.body;

    const client = await pool.connect();
    try {
        const query = `
            INSERT INTO word_stats (userid, word, wins, losses)
            VALUES ($1, $2, $3, (1-$3))
            ON CONFLICT (userid, word) DO UPDATE
            SET wins = word_stats.wins + 1,
            losses = word_stats.losses + 1;
        `;
        const values = [id, word, win]
        const result = await client.query(query, values)
        console.log("Updated stats successfully")
    } catch (err) {
        console.log("Error updating word stats: ", err)
    } finally {
        client.release
    }
})

app.get('/fetchStats', async (req, res) => {
    const userid = req.query.userid;

    const client = await pool.connect();
    try {
        const query = `SELECT
            ws.word,
            ws.wins + ws.losses AS played,
            ws.wins AS won,
            ws.losses AS lost
            FROM users u
            JOIN word_stats ws ON u.id = ws.userid
            WHERE u.id = $1
        `;
        const values = [userid];
        const result = await client.query(query, values);

        res.status(200).json(result.rows);
        console.log("Fetched stats successfully");
    } catch (err) {
        console.error('Error fetching user stats:', err);
        res.status(500).json({ error: 'Failed to retrieve user stats' });
    } finally {
        client.release();
    }
});