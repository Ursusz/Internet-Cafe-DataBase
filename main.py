from flask import Flask, redirect, request, render_template, session, flash
import oracledb

app = Flask(__name__)

app.config.from_pyfile('config.py')
app.secret_key = 'secret key'

def get_db_conn():
    return oracledb.connect(
        user = app.config['ORACLE_USER'],
        password = app.config['ORACLE_PASSWORD'],
        dsn = app.config['ORACLE_DSN'] 
    )

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/show-data', methods=['GET', 'POST'])
def show_data():
    if request.method == 'POST':
        tabel = request.form.get('tabel', 'client') 
        session['last_table'] = tabel
    else:
        tabel = session.get('last_table', 'client')

    conn = get_db_conn()
    cursor = conn.cursor()

    cursor.execute(f"SELECT * FROM {tabel}")
    rows = cursor.fetchall()

    cols = [col[0] for col in cursor.description]
    conn.close()

    return render_template('show_data.html', rows=rows, cols=cols, tabel=tabel)


@app.route('/edit/<tabel>/<id_name>/<col_name>/<int:id>', methods=['POST'])
def edit(tabel, id_name, col_name, id):
    conn = get_db_conn()
    cursor = conn.cursor()

    new_value = request.form.get(col_name)

    sql = f"UPDATE {tabel} SET {col_name} = :new_value WHERE {id_name} = :id"
    try:
        cursor.execute(sql, {"new_value": new_value, "id": id})
        conn.commit()
    except oracledb.DatabaseError as e:
        error_message = e.args[0].message if hasattr(e.args[0], 'message') else str(e)
        flash(f'Eroare: {error_message}', 'error')
        return redirect('/show-data?tabel='+tabel)
    finally:
        conn.close()

    last_table = session.get('last_table', 'client')
    return redirect(f'/show-data?tabel={last_table}')


@app.route('/delete/<tabel>/<col_name>/<int:id>', methods=['POST'])
def delete(tabel, col_name, id):
    conn = get_db_conn()
    cursor = conn.cursor()

    sql = f"DELETE FROM {tabel} WHERE {col_name} = :id"
    
    cursor.execute(sql, {"id": id})
    conn.commit()
    
    conn.close()
    
    last_table = session.get('last_table', 'client')
    return redirect('/show-data?tabel=' + last_table)

@app.route('/insert/<tabel>', methods=['POST'])
def insert_data(tabel):
    data = request.form.to_dict()

    cols = []
    vals = []
    params = {}

    for key, value in data.items():
        if "DATA" in key:
            cols.append(key)
            vals.append(f"TO_DATE(:{key}, 'yyyy-mm-dd hh24:mi')")
            params[key] = value
        else:
            cols.append(key)
            vals.append(f":{key}")
            params[key] = value

    query = f"INSERT INTO {tabel} ({', '.join(cols)}) VALUES ({', '.join(vals)})"
    print(query)
    conn = get_db_conn()
    cursor = conn.cursor()

    try:
        cursor.execute(query, params)
        conn.commit()
    except oracledb.DatabaseError as e:
        error_message = e.args[0].message if hasattr(e.args[0], 'message') else str(e)
        flash(f'Eroare: {error_message}', 'error')
        return redirect('/show-data?tabel=' + tabel)
    finally:
        conn.close()

    return redirect('/show-data')

@app.route('/sort/<tabel>', methods=['POST'])
def sort_data(tabel):
    sort_columns = request.form.getlist('sort_columns')
    sort_directions = request.form.getlist('sort_directions')

    order_by_clauses = []
    for col, direction in zip(sort_columns, sort_directions):
        order_by_clauses.append(f"{col} {direction}")

    order_by = ", ".join(order_by_clauses) if order_by_clauses else "1"

    conn = get_db_conn()
    cursor = conn.cursor()

    query = f"SELECT * FROM {tabel} ORDER BY {order_by}"
    cursor.execute(query)

    rows = cursor.fetchall()
    cols = [col[0] for col in cursor.description]

    conn.close()

    return render_template('show_data.html', rows=rows, cols=cols, tabel=tabel)

@app.route('/filter-sali', methods=['GET', 'POST'])
def filter_sali():
    conn = get_db_conn()
    cursor = conn.cursor()

    min_performance = request.form.get('min_performance')
    
    query = """
        SELECT nr_sala, AVG(grad_performanta)
        FROM statie
        GROUP BY nr_sala
        HAVING AVG(grad_performanta) >= :min_performance
    """
    cursor.execute(query, {'min_performance': min_performance})

    rows = cursor.fetchall()
    cols = [col[0] for col in cursor.description]

    conn.close()

    return render_template('filter_sali.html', rows=rows, cols=cols, min_performance=min_performance)

@app.route('/filter-periferice', methods=['GET', 'POST'])
def filter_periferice():
    conn = get_db_conn()
    cursor = conn.cursor()

    max_sala = request.form.get('max_sala')
    SO = request.form.get('sistem_operare')

    query = """
        SELECT id_periferice
        FROM sala 
        LEFT JOIN statie USING (nr_sala) 
        LEFT JOIN periferice USING (id_statie)
        WHERE nr_sala = :max_sala AND sistem_operare = :SO
    """

    cursor.execute(query, {"max_sala": max_sala, "SO": SO})
    
    rows = cursor.fetchall()
    cols = [col[0] for col in cursor.description]
    conn.close()

    return render_template('filter_periferice.html', rows=rows, cols=cols, max_sala=max_sala, SO=SO)


if __name__ == '__main__':
    app.run(debug=True)
