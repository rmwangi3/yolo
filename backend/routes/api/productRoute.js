const express = require('express')
const router = express.Router();

// Product Model
const Product = require('../../models/Products');

// @route GET /products
// @desc Get ALL products
router.get('/', async (req, res) => {
    try {
        const products = await Product.find({})
        res.json(products)
    } catch (error) {
        console.error(error)
        res.status(500).json({ error: 'Failed to fetch products' })
    }
})

// @route POST /products
// @desc  Create a product
router.post('/', async (req, res) => {
    try {
        const newProduct = new Product({
            name: req.body.name,
            description: req.body.description,
            price: req.body.price,
            quantity: req.body.quantity,
            photo: req.body.photo
        })
        const product = await newProduct.save()
        res.json(product)
    } catch (err) {
        console.error(err)
        res.status(500).json({ error: 'Failed to create product' })
    }
})
// @route PUT api/products/:id
// @desc  Update a product
router.put('/:id', async (req, res) => {
    try {
        await Product.updateOne({ _id: req.params.id }, {
            name: req.body.name,
            description: req.body.description,
            price: req.body.price,
            quantity: req.body.quantity,
            photo: req.body.photo
        }, { upsert: true })
        res.json({ success: true })
    } catch (err) {
        console.error(err)
        res.status(500).json({ error: 'Failed to update product' })
    }
})
// @route DELETE api/products/:id
// @desc  Delete a product
router.delete('/:id', async (req, res) => {
    try {
        await Product.deleteOne({ _id: req.params.id })
        res.json({ success: true })
    } catch (err) {
        console.error(err)
        res.status(500).json({ error: 'Failed to delete product' })
    }
})

module.exports = router;